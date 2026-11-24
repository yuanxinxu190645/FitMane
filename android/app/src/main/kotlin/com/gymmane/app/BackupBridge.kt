package com.gymmane.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodChannel
import java.io.File

object BackupBridge {
    const val CHANNEL = "gymmane/backup"
    private const val REQUEST_CODE = 4272
    private const val REQUEST_CODE_FILE = 4273
    private var pending: MethodChannel.Result? = null
    private var pendingFile: MethodChannel.Result? = null

    fun attach(activity: Activity, channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> pick(activity, result)
                "pickFile" -> {
                    val name = call.argument<String>("name") ?: "FitMane-AI-Summary.md"
                    val mime = call.argument<String>("mime") ?: "text/markdown"
                    pickFile(activity, name, mime, result)
                }
                "writeFile" -> {
                    val uri = call.argument<String>("uri")
                    val content = call.argument<String>("content")
                    if (uri == null || content == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val context = activity.applicationContext
                    Thread {
                        val ok = writeFile(context, Uri.parse(uri), content)
                        activity.runOnUiThread { result.success(ok) }
                    }.start()
                }
                "check" -> result.success(hasAccess(activity, call.argument<String>("uri")))
                "write" -> {
                    val uri = call.argument<String>("uri")
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    val prefix = call.argument<String>("prefix") ?: ""
                    val keep = call.argument<Int>("keep") ?: 5
                    if (uri == null || path == null || name == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val context = activity.applicationContext
                    Thread {
                        val ok = write(context, Uri.parse(uri), File(path), name, prefix, keep)
                        activity.runOnUiThread { result.success(ok) }
                    }.start()
                }
                "list" -> {
                    val uri = call.argument<String>("uri")
                    val prefix = call.argument<String>("prefix") ?: ""
                    if (uri == null) {
                        result.success(emptyList<String>())
                        return@setMethodCallHandler
                    }
                    val context = activity.applicationContext
                    Thread {
                        val names = list(context, Uri.parse(uri), prefix).map { it.second }
                        activity.runOnUiThread { result.success(names) }
                    }.start()
                }
                "read" -> {
                    val uri = call.argument<String>("uri")
                    val name = call.argument<String>("name")
                    val path = call.argument<String>("path")
                    if (uri == null || name == null || path == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val context = activity.applicationContext
                    Thread {
                        val ok = read(context, Uri.parse(uri), name, File(path))
                        activity.runOnUiThread { result.success(ok) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pick(activity: Activity, result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (e: Exception) {
            pending = null
            result.success(null)
        }
    }

    private fun pickFile(activity: Activity, name: String, mime: String, result: MethodChannel.Result) {
        pendingFile?.success(null)
        pendingFile = result
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mime
            putExtra(Intent.EXTRA_TITLE, name)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        try {
            activity.startActivityForResult(intent, REQUEST_CODE_FILE)
        } catch (e: Exception) {
            pendingFile = null
            result.success(null)
        }
    }

    fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_FILE) {
            val result = pendingFile ?: return true
            pendingFile = null
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                result.success(null)
                return true
            }
            var persisted = false
            try {
                activity.contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
                persisted = true
            } catch (e: Exception) {
                persisted = false
            }
            result.success(
                mapOf(
                    "uri" to uri.toString(),
                    "name" to docDisplayName(activity, uri),
                    "persisted" to persisted,
                ),
            )
            return true
        }
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            activity.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (e: Exception) {
            result.success(null)
            return true
        }
        result.success(mapOf("uri" to uri.toString(), "name" to folderName(activity, uri)))
        return true
    }

    private fun docDisplayName(context: Context, uri: Uri): String {
        try {
            context.contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use {
                if (it.moveToFirst()) {
                    val v = it.getString(0)
                    if (!v.isNullOrBlank()) return v
                }
            }
        } catch (e: Exception) {
        }
        return uri.lastPathSegment?.substringAfterLast('/') ?: "FitMane-AI-Summary.md"
    }

    private fun writeFile(context: Context, uri: Uri, content: String): Boolean {
        val bytes = content.toByteArray(Charsets.UTF_8)
        val resolver = context.contentResolver
        return try {
            val out = try {
                resolver.openOutputStream(uri, "wt")
            } catch (e: Exception) {
                resolver.openOutputStream(uri, "w")
            }
            out?.use {
                it.write(bytes)
                it.flush()
            } != null
        } catch (e: Exception) {
            false
        }
    }

    private fun hasAccess(context: Context, uri: String?): Boolean {
        if (uri == null) return false
        val tree = Uri.parse(uri)
        return context.contentResolver.persistedUriPermissions.any { it.uri == tree && it.isWritePermission }
    }

    private fun folderName(context: Context, tree: Uri): String {
        val doc = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        try {
            context.contentResolver.query(doc, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
                ?.use { if (it.moveToFirst()) return it.getString(0) ?: "" }
        } catch (e: Exception) {
        }
        return DocumentsContract.getTreeDocumentId(tree).substringAfterLast(':').substringAfterLast('/')
    }

    private fun write(context: Context, tree: Uri, source: File, name: String, prefix: String, keep: Int): Boolean {
        val resolver = context.contentResolver
        val parentId = try {
            DocumentsContract.getTreeDocumentId(tree)
        } catch (e: Exception) {
            return false
        }
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, parentId)
        val doc = try {
            DocumentsContract.createDocument(resolver, parent, "application/zip", name)
        } catch (e: Exception) {
            null
        } ?: return false
        val written = try {
            resolver.openOutputStream(doc, "w")?.use { out -> source.inputStream().use { it.copyTo(out) } } != null
        } catch (e: Exception) {
            false
        }
        if (!written) {
            try {
                DocumentsContract.deleteDocument(resolver, doc)
            } catch (e: Exception) {
            }
            return false
        }
        if (prefix.isNotEmpty()) prune(context, tree, parentId, prefix, keep.coerceAtLeast(1))
        return true
    }

    private fun list(context: Context, tree: Uri, prefix: String): List<Pair<String, String>> {
        val parentId = try {
            DocumentsContract.getTreeDocumentId(tree)
        } catch (e: Exception) {
            return emptyList()
        }
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
        val found = mutableListOf<Pair<String, String>>()
        try {
            context.contentResolver.query(
                children,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null, null, null,
            )?.use {
                while (it.moveToNext()) {
                    val id = it.getString(0) ?: continue
                    val name = it.getString(1) ?: continue
                    if (name.startsWith(prefix) && name.endsWith(".zip")) found.add(id to name)
                }
            }
        } catch (e: Exception) {
        }
        return found
    }

    private fun read(context: Context, tree: Uri, name: String, target: File): Boolean {
        val id = list(context, tree, name).firstOrNull { it.second == name }?.first ?: return false
        return try {
            val doc = DocumentsContract.buildDocumentUriUsingTree(tree, id)
            context.contentResolver.openInputStream(doc)?.use { input ->
                target.outputStream().use { input.copyTo(it) }
            } != null
        } catch (e: Exception) {
            false
        }
    }

    private fun prune(context: Context, tree: Uri, parentId: String, prefix: String, keep: Int) {
        val resolver = context.contentResolver
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
        val found = mutableListOf<Pair<String, String>>()
        try {
            resolver.query(
                children,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null, null, null,
            )?.use {
                while (it.moveToNext()) {
                    val id = it.getString(0) ?: continue
                    val name = it.getString(1) ?: continue
                    if (name.startsWith(prefix) && name.endsWith(".zip")) found.add(id to name)
                }
            }
        } catch (e: Exception) {
            return
        }
        for ((id, _) in found.sortedByDescending { it.second }.drop(keep)) {
            try {
                DocumentsContract.deleteDocument(resolver, DocumentsContract.buildDocumentUriUsingTree(tree, id))
            } catch (e: Exception) {
            }
        }
    }
}
