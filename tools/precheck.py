#!/usr/bin/env python3
"""Local pre-push validation script for FitMane (stdlib only).

Runs fast static checks before pushing to GitHub Actions:
1. Version consistency across pubspec.yaml, about_screen.dart, app_updater.dart
2. Catalog integrity across exercise_catalog.dart, gym_pack.dart, pro_packs.dart
3. Alias collision check against upstream test/*.dart literals
4. ExtraStrings duplicate member check
5. Hardcoded English UI & calendar word scan (mirrors test/i18n_test.dart)
6. GitHub Actions workflow YAML sanity checks
"""

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_text(rel_path: str) -> str:
    with open(os.path.join(ROOT, rel_path), encoding='utf-8') as f:
        return f.read()


def check_versions() -> None:
    pub = read_text('pubspec.yaml')
    about = read_text('lib/screens/about_screen.dart')
    upd = read_text('lib/services/app_updater.dart')

    m_pub = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$', pub, re.M)
    m_about = re.search(r"const kAppVersion = '([^']+)';", about)
    m_upd_v = re.search(r"const String kCurrentAppVersion = '([^']+)';", upd)
    m_upd_b = re.search(r'const int kCurrentAppBuild = ([0-9]+);', upd)

    assert m_pub and m_about and m_upd_v and m_upd_b, 'Missing version declarations'
    pub_v, pub_b = m_pub.group(1), int(m_pub.group(2))
    assert m_about.group(1) == pub_v, f'about_screen {m_about.group(1)} != pubspec {pub_v}'
    assert m_upd_v.group(1) == pub_v, f'app_updater {m_upd_v.group(1)} != pubspec {pub_v}'
    assert int(m_upd_b.group(1)) == pub_b, f'app_updater build {m_upd_b.group(1)} != pubspec {pub_b}'
    print(f'[OK] Version consistent: {pub_v}+{pub_b}')


def _parse_exercises(txt: str):
    items = []
    for m in re.finditer(r'Exercise\((.*?)\n  \),', txt, re.S):
        blk = m.group(1)

        def gf(k: str) -> str:
            mm = re.search(rf"{k}:\s*'((?:\\'|[^'])*)'", blk)
            if mm:
                return mm.group(1).replace("\\'", "'")
            mm = re.search(rf'{k}:\s*"([^"]*)"', blk)
            return mm.group(1) if mm else ''

        sec_m = re.search(r'secondary:\s*\[([^\]]*)\]', blk, re.S)
        sec = re.findall(r"'([^']+)'", sec_m.group(1)) if sec_m else []
        steps_m = re.search(r'steps:\s*\[(.*?)\],', blk, re.S)
        steps = re.findall(r"'((?:\\'|[^'])*)'", steps_m.group(1)) if steps_m else []
        aliases_m = re.search(r'aliases:\s*\[([^\]]*)\]', blk, re.S)
        aliases = [
            a.replace("\\'", "'")
            for a in (re.findall(r"'((?:\\'|[^'])*)'", aliases_m.group(1)) if aliases_m else [])
        ]
        items.append({
            'id': gf('id'),
            'name': gf('name'),
            'primary': gf('primary'),
            'secondary': sec,
            'equipment': gf('equipment'),
            'difficulty': gf('difficulty'),
            'art': gf('art'),
            'kind': gf('kind'),
            'mode': gf('mode'),
            'steps': steps,
            'aliases': aliases,
        })
    return items


def check_catalog() -> None:
    ec = read_text('lib/catalog/exercise_catalog.dart')
    gp = read_text('lib/catalog/gym_pack.dart')
    pp = read_text('lib/catalog/pro_packs.dart')
    ex_model = read_text('lib/models/exercise.dart')

    km_block = re.search(r'kMuscles\s*=\s*\[(.*?)\];', ex_model, re.S).group(1)
    valid_muscles = set(re.findall(r"'([^']+)'", km_block))
    valid_equips = {
        'Barbell', 'Dumbbell', 'Cable', 'Machine', 'Bodyweight',
        'Weighted', 'Band', 'Kettlebell', 'Rings', 'Other',
    }
    valid_diffs = {'Beginner', 'Intermediate', 'Advanced'}
    valid_kinds = {'', 'strength', 'calisthenics', 'cardio', 'stretch', 'sport'}
    valid_modes = {'', 'cardio', 'time'}
    art_stems = {
        os.path.splitext(os.path.basename(p))[0]
        for p in glob.glob(os.path.join(ROOT, 'assets/art/*.txt'))
    }

    ec_items = _parse_exercises(ec)
    gp_items = _parse_exercises(gp)
    pp_items = _parse_exercises(pp)
    all_items = ec_items + gp_items + pp_items

    ids = [x['id'] for x in all_items]
    names = [x['name'].lower() for x in all_items]
    assert len(ids) == len(set(ids)), 'Duplicate exercise IDs found!'
    assert len(names) == len(set(names)), 'Duplicate exercise names found!'

    for x in gp_items + pp_items:
        assert x['primary'] in valid_muscles, f"Invalid primary in {x['id']}: {x['primary']}"
        for s in x['secondary']:
            assert s in valid_muscles and s != x['primary'], f"Invalid secondary in {x['id']}: {s}"
        assert x['equipment'] in valid_equips, f"Invalid equipment in {x['id']}: {x['equipment']}"
        assert x['difficulty'] in valid_diffs, f"Invalid difficulty in {x['id']}: {x['difficulty']}"
        assert x['kind'] in valid_kinds, f"Invalid kind in {x['id']}: {x['kind']}"
        assert x['mode'] in valid_modes, f"Invalid mode in {x['id']}: {x['mode']}"
        assert x['art'] in art_stems, f"Missing art file for {x['id']}: {x['art']}"
        assert len(x['steps']) >= 2, f"Missing EN steps for {x['id']}"

    # Verify Chinese maps cover 100% of expansion packs
    for label, src, items, map_prefix in [
        ('gym_pack', gp, gp_items, 'kGymPack'),
        ('pro_packs', pp, pp_items, 'kProPack'),
    ]:
        nm = re.search(rf'const Map<String, String> {map_prefix}NameZh = \{{(.*?)\n\}};', src, re.S)
        sm = re.search(rf'const Map<String, List<String>> {map_prefix}StepsZh = \{{(.*?)\n\}};', src, re.S)
        assert nm and sm, f'Missing Zh maps in {label}'
        zh_names = {k for k, v in re.findall(r"'([^']+)':\s*'([^']+)'", nm.group(1)) if v.strip()}
        zh_steps = {k for k, _ in re.findall(r"'([^']+)':\s*\[(.*?)\],", sm.group(1), re.S)}
        expected = {x['id'] for x in items}
        assert zh_names == expected, f'{label} NameZh mismatch: {expected ^ zh_names}'
        assert zh_steps == expected, f'{label} StepsZh mismatch: {expected ^ zh_steps}'

    # Check alias collisions against upstream test literals
    exp_aliases = {a.lower() for x in (gp_items + pp_items) for a in x['aliases']}
    collisions = []
    for p in glob.glob(os.path.join(ROOT, 'test', '**', '*.dart'), recursive=True):
        if os.path.basename(p) == 'fitmane_extensions_test.dart':
            continue
        src = read_text(os.path.relpath(p, ROOT))
        for m in re.finditer(r"'([^'\n]{3,50})'", src):
            if m.group(1).lower() in exp_aliases:
                collisions.append((os.path.basename(p), m.group(1)))
    assert not collisions, f'Alias collisions with upstream tests: {collisions}'
    print(f'[OK] Catalog validated: {len(ec_items)} base + {len(gp_items)} gym + {len(pp_items)} pro = {len(all_items)} unique exercises')


def check_extra_strings() -> None:
    src = read_text('lib/l10n/extra_strings.dart')
    members = re.findall(r'static\s+(?:bool|String|int|double|List<String>)\s+(?:get\s+)?([A-Za-z0-9_]+)', src)
    dups = sorted({m for m in members if members.count(m) > 1})
    assert not dups, f'Duplicate ExtraStrings members: {dups}'
    print(f'[OK] ExtraStrings unique members: {len(members)}')


def check_i18n_rules() -> None:
    pat = re.compile(r"""(?:Text\(\s*|label:\s*|hintText:\s*|ScreenTitle\(\s*|title:\s*)'([^']{2,})'""")
    allowed = {'GymMane', 'GYMMANE', 'GYM · MANE', 'M', 'F', 'kg', 'lb', 'cm', 'EN', 'ES', 'NFC'}
    cal_words = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Jan', 'Feb', 'Dec']
    offenders = []
    cal_off = []
    for sub in ['lib/screens', 'lib/widgets', 'lib/app']:
        for p in glob.glob(os.path.join(ROOT, sub, '**', '*.dart'), recursive=True):
            src = read_text(os.path.relpath(p, ROOT))
            for m in pat.finditer(src):
                txt = m.group(1)
                if '$' in txt or not re.search(r'[A-Za-z]{2}', txt):
                    continue
                if not (re.match(r'^[A-Z]', txt) or ' ' in txt):
                    continue
                if txt in allowed:
                    continue
                offenders.append(f'{os.path.basename(p)}: "{txt}"')
            for w in cal_words:
                if f"'{w}'" in src:
                    cal_off.append(f'{os.path.basename(p)}: "{w}"')
    assert not offenders, f'Hardcoded English UI strings: {offenders}'
    assert not cal_off, f'Hardcoded calendar words: {cal_off}'
    print('[OK] i18n hardcoded English & calendar scan: 0 offenders')


def check_workflows() -> None:
    for p in glob.glob(os.path.join(ROOT, '.github/workflows/*.yml')):
        src = read_text(os.path.relpath(p, ROOT))
        assert '\t' not in src, f'Tab character found in {p}'
    wf = read_text('.github/workflows/build-apk.yml')
    assert '  check:' in wf and '  release:' in wf and 'needs: check' in wf
    print('[OK] Workflow YAML sanity passed')


def main() -> int:
    check_versions()
    check_catalog()
    check_extra_strings()
    check_i18n_rules()
    check_workflows()
    print('ALL_PRECHECKS_PASSED')
    return 0


if __name__ == '__main__':
    sys.exit(main())
