package com.prajjwalujjaini.sortogram_mng_strg.sortogram_mng_strg;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.util.Log;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.provider.Settings;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.io.BufferedInputStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/** SortogramMngStrgPlugin */
public class SortogramMngStrgPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {
  private static final String TAG = "SortogramMngStrg";
  private static final int PERMISSION_REQUEST_CODE = 123;
  private static final int MANAGE_STORAGE_PERMISSION_REQUEST_CODE = 456;

  private MethodChannel channel;
  private Context context;
  private Activity activity;
  private Result pendingResult;
  private String pendingSourcePath;
  private String pendingDestPath;

  private static final Set<String> SUPPORTED_IMAGE_TYPES = new HashSet<>(Arrays.asList(
      "jpg", "jpeg", "png", "webp"));

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    Log.d(TAG, "Plugin attached to engine");
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "sortogram_mng_strg");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Log.d(TAG, "Method called: " + call.method);
    switch (call.method) {
      case "moveImage":
        String sourcePath = call.argument("sourcePath");
        String destPath = call.argument("destinationPath");
        Log.d(TAG, "Moving image from: " + sourcePath + " to: " + destPath);
        if (sourcePath == null || destPath == null) {
          Log.e(TAG, "Invalid arguments: source or destination path is null");
          result.error("INVALID_ARGUMENTS", "Source and destination paths are required", null);
          return;
        }
        handleMoveImage(sourcePath, destPath, result);
        break;
      case "getRealPath":
        String path = call.argument("path");
        Log.d(TAG, "Getting real path for: " + path);
        if (path == null) {
          Log.e(TAG, "Invalid arguments: path is null");
          result.error("INVALID_ARGUMENTS", "Path is required", null);
          return;
        }
        getRealPath(path, result);
        break;
      case "getPlatformVersion":
        String version = "Android " + android.os.Build.VERSION.RELEASE;
        Log.d(TAG, "Platform version requested: " + version);
        result.success(version);
        break;
      default:
        Log.w(TAG, "Method not implemented: " + call.method);
        result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    context = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  private void handleMoveImage(String sourcePath, String destPath, Result result) {
    Log.d(TAG, "Handling image move request");
    if (activity == null) {
      Log.e(TAG, "Activity is null, cannot proceed with image move");
      result.error("ACTIVITY_NULL", "Activity is null", null);
      return;
    }

    pendingSourcePath = sourcePath;
    pendingDestPath = destPath;
    pendingResult = result;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      Log.d(TAG, "Android 11+ (API 30+): Checking MANAGE_EXTERNAL_STORAGE permission");
      if (!Environment.isExternalStorageManager()) {
        Log.i(TAG, "Requesting MANAGE_EXTERNAL_STORAGE permission");
        try {
          Intent intent = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
          activity.startActivityForResult(intent, MANAGE_STORAGE_PERMISSION_REQUEST_CODE);
          Log.d(TAG, "Permission request intent sent successfully");
        } catch (Exception e) {
          Log.e(TAG, "Error launching permission request: " + e.getMessage());
          result.error("PERMISSION_REQUEST_FAILED", "Failed to launch permission request", e.getMessage());
        }
        return;
      }
      Log.d(TAG, "MANAGE_EXTERNAL_STORAGE permission already granted");
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      Log.d(TAG, "Android 6+ (API 23+): Checking WRITE_EXTERNAL_STORAGE permission");
      if (ContextCompat.checkSelfPermission(context,
          Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
        Log.i(TAG, "Requesting WRITE_EXTERNAL_STORAGE permission");
        ActivityCompat.requestPermissions(activity,
            new String[] { Manifest.permission.WRITE_EXTERNAL_STORAGE },
            PERMISSION_REQUEST_CODE);
        return;
      }
      Log.d(TAG, "WRITE_EXTERNAL_STORAGE permission already granted");
    }

    // If we reach here, we have the necessary permissions
    performImageMove(sourcePath, destPath, result);
  }

  private void performImageMove(String sourcePath, String destPath, Result result) {
    Log.d(TAG, "Starting image move operation");
    Log.d(TAG, "Source: " + sourcePath);
    Log.d(TAG, "Destination: " + destPath);

    File sourceFile = new File(sourcePath);
    File destDir = new File(destPath).getParentFile();
    File destFile = new File(destPath);

    try {
      if (!sourceFile.exists()) {
        Log.e(TAG, "Source file does not exist: " + sourcePath);
        result.error("SOURCE_NOT_FOUND", "Source file does not exist", null);
        return;
      }

      if (!destDir.exists() && !destDir.mkdirs()) {
        Log.e(TAG, "Failed to create destination directory: " + destDir.getAbsolutePath());
        result.error("DEST_CREATE_FAILED", "Could not create destination directory", null);
        return;
      }

      if (destFile.exists()) {
        Log.e(TAG, "Destination file already exists: " + destPath);
        result.error("DEST_EXISTS", "Destination file already exists", null);
        return;
      }

      String fileExtension = getFileExtension(sourcePath).toLowerCase();
      Log.d(TAG, "File extension: " + fileExtension);
      if (!SUPPORTED_IMAGE_TYPES.contains(fileExtension)) {
        Log.e(TAG, "Unsupported file type: " + fileExtension);
        result.error("UNSUPPORTED_TYPE", "File type not supported", null);
        return;
      }

      // Move the file
      Log.d(TAG, "Moving file...");
      boolean success = moveFile(sourceFile, destFile);
      if (!success) {
        Log.e(TAG, "Failed to move file");
        result.error("MOVE_FAILED", "Failed to move file", null);
        return;
      }
      Log.d(TAG, "File moved successfully");

      // Update MediaStore
      Log.d(TAG, "Updating MediaStore...");
      updateMediaStore(sourceFile, destFile);
      Log.d(TAG, "MediaStore updated successfully");
      result.success(true);

    } catch (Exception e) {
      result.error("UNKNOWN_ERROR", e.getMessage(), null);
    }
  }

  private boolean moveFile(File sourceFile, File destFile) throws IOException {
    Log.d(TAG, "Moving file from: " + sourceFile.getAbsolutePath() + " to: " + destFile.getAbsolutePath());
    long startTime = System.currentTimeMillis();
    long fileSize = sourceFile.length();

    // First verify we can delete the source file
    if (!sourceFile.canWrite()) {
      Log.e(TAG, "Source file is not writable, cannot delete after copy");
      throw new IOException("Source file is not writable");
    }

    boolean success = false;
    FileInputStream in = null;
    FileOutputStream out = null;

    try {
      in = new FileInputStream(sourceFile);
      out = new FileOutputStream(destFile);

      byte[] buffer = new byte[8192]; // Increased buffer size
      int length;
      long totalBytesRead = 0;

      while ((length = in.read(buffer)) > 0) {
        out.write(buffer, 0, length);
        totalBytesRead += length;
        if (totalBytesRead % (1024 * 1024) == 0) { // Log progress every 1MB
          Log.d(TAG, String.format("Copy progress: %.1f%%", (totalBytesRead * 100.0) / fileSize));
        }
      }

      // Force write to disk
      out.flush();
      out.getFD().sync(); // Ensure data is written to disk

      // Close streams before further operations
      in.close();
      out.close();
      in = null;
      out = null;

      // Verify destination file exists
      if (!destFile.exists()) {
        Log.e(TAG, "Destination file does not exist after copy");
        throw new IOException("Destination file was not created");
      }

      // Verify the copy was successful by checking file sizes
      Log.i(TAG,
          "????????????????????????????  Verify the copy was successful by checking file sizes ************************");
      if (destFile.length() != sourceFile.length()) {
        Log.e(TAG, "File sizes don't match after copy");
        destFile.delete(); // Clean up the incomplete copy
        throw new IOException("File copy was incomplete");
      }

      // Verify file contents (optional, but more thorough)
      if (!verifyFileContents(sourceFile, destFile)) {
        Log.e(TAG, "File contents verification failed");
        destFile.delete();
        throw new IOException("File contents do not match");
      }

      // Try to delete the source file
      if (!sourceFile.delete()) {
        Log.e(TAG, "Failed to delete source file");
        destFile.delete(); // Clean up the destination since move failed
        throw new IOException("Could not delete source file");
      }

      success = true;
      Log.d(TAG, "File successfully moved");
      Log.d(TAG, "Move operation completed in " + (System.currentTimeMillis() - startTime) + "ms");

    } catch (IOException e) {
      Log.e(TAG, "Error during file move: " + e.getMessage());
      // Clean up destination file if it exists
      if (destFile.exists()) {
        destFile.delete();
      }
      throw e;
    } finally {
      // Clean up resources in finally block
      if (in != null) {
        try {
          in.close();
        } catch (IOException e) {
          Log.w(TAG, "Error closing input stream: " + e.getMessage());
        }
      }
      if (out != null) {
        try {
          out.close();
        } catch (IOException e) {
          Log.w(TAG, "Error closing output stream: " + e.getMessage());
        }
      }
    }

    Log.e(TAG, "At time of return success from moveFile function : " + success);
    return success;
  }

  // Add this new helper method for content verification
  private boolean verifyFileContents(File sourceFile, File destFile) throws IOException {
    if (sourceFile.length() != destFile.length()) {
      Log.d(TAG, "File size mismatch during verification");
      return false;
    }

    try {
      String sourceHash = calculateMD5(sourceFile);
      String destHash = calculateMD5(destFile);

      boolean matches = sourceHash != null && sourceHash.equals(destHash);
      Log.d(TAG, "File hash comparison - Source: " + sourceHash + ", Dest: " + destHash);

      return matches;
    } catch (Exception e) {
      Log.e(TAG, "Error during hash verification: " + e.getMessage());
      throw new IOException("Hash verification failed", e);
    }
  }

  private String calculateMD5(File file) throws IOException {
    try {
      MessageDigest digest = MessageDigest.getInstance("MD5");
      try (InputStream is = new BufferedInputStream(new FileInputStream(file))) {
        byte[] buffer = new byte[8192];
        int read;
        while ((read = is.read(buffer)) > 0) {
          digest.update(buffer, 0, read);
        }
        byte[] md5sum = digest.digest();
        BigInteger bigInt = new BigInteger(1, md5sum);
        return String.format("%032x", bigInt);
      }
    } catch (NoSuchAlgorithmException e) {
      Log.e(TAG, "MD5 algorithm not available");
      throw new IOException("MD5 algorithm not available", e);
    }
  }

  private void updateMediaStore(File sourceFile, File destFile) {
    Log.d(TAG, "Updating MediaStore");
    ContentResolver resolver = context.getContentResolver();

    // Remove the old entry
    Log.d(TAG, "Removing old MediaStore entry for: " + sourceFile.getAbsolutePath());
    Uri contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
    int deletedRows = resolver.delete(contentUri,
        MediaStore.Images.Media.DATA + "=?",
        new String[] { sourceFile.getAbsolutePath() });
    Log.d(TAG, "Deleted " + deletedRows + " rows from MediaStore");

    // Add the new entry
    Log.d(TAG, "Adding new MediaStore entry for: " + destFile.getAbsolutePath());
    ContentValues values = new ContentValues();
    values.put(MediaStore.Images.Media.DATA, destFile.getAbsolutePath());
    String mimeType = getMimeType(destFile.getName());
    values.put(MediaStore.Images.Media.MIME_TYPE, mimeType);
    values.put(MediaStore.Images.Media.DATE_MODIFIED, System.currentTimeMillis() / 1000);
    Log.d(TAG, "MIME type: " + mimeType);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      Log.d(TAG, "Setting IS_PENDING flag for Android 10+");
      values.put(MediaStore.Images.Media.IS_PENDING, 1);
    }

    Uri uri = resolver.insert(contentUri, values);
    Log.d(TAG, "New MediaStore entry URI: " + uri);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && uri != null) {
      Log.d(TAG, "Clearing IS_PENDING flag");
      values.clear();
      values.put(MediaStore.Images.Media.IS_PENDING, 0);
      int updatedRows = resolver.update(uri, values, null, null);
      Log.d(TAG, "Updated " + updatedRows + " rows in MediaStore");
    }

    // Ensure the media scanner is aware of the changes
    Log.d(TAG, "Triggering media scanner for: " + destFile.getAbsolutePath());
    MediaScannerConnection.scanFile(context,
        new String[] { destFile.getAbsolutePath() },
        new String[] { mimeType },
        (path, uri1) -> Log.d(TAG, "Media scan completed for: " + path + " URI: " + uri1));
  }

  private String getFileExtension(String path) {
    int lastDot = path.lastIndexOf('.');
    if (lastDot < 0) {
      return "";
    }
    return path.substring(lastDot + 1);
  }

  private String getMimeType(String fileName) {
    String extension = getFileExtension(fileName).toLowerCase();
    switch (extension) {
      case "jpg":
      case "jpeg":
        return "image/jpeg";
      case "png":
        return "image/png";
      case "webp":
        return "image/webp";
      default:
        return "image/*";
    }
  }

  private void getRealPath(String path, Result result) {
    Log.d(TAG, "Getting real path for: " + path);
    try {
      if (context == null) {
        Log.e(TAG, "Context is null");
        result.error("CONTEXT_NULL", "Context is null", null);
        return;
      }

      // If the path is already a real file path and exists, return it
      File file = new File(path);
      if (file.exists()) {
        Log.d(TAG, "File exists at path, returning: " + path);
        result.success(path);
        return;
      }

      // Query MediaStore for the real path
      ContentResolver resolver = context.getContentResolver();
      String[] projection = { MediaStore.Images.Media.DATA };
      String selection = MediaStore.Images.Media.DATA + "=?";
      String[] selectionArgs = { path };

      try (Cursor cursor = resolver.query(
          MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
          projection,
          selection,
          selectionArgs,
          null)) {

        if (cursor != null && cursor.moveToFirst()) {
          String realPath = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA));
          Log.d(TAG, "Found real path: " + realPath);

          // Verify the file exists
          if (new File(realPath).exists()) {
            result.success(realPath);
            return;
          }
        }
      }

      // If we get here, we couldn't find the real path
      Log.e(TAG, "Could not find real path for: " + path);
      result.error("PATH_NOT_FOUND", "Could not find real path for file", null);

    } catch (Exception e) {
      Log.e(TAG, "Error getting real path: " + e.getMessage());
      result.error("UNEXPECTED_ERROR", "Error getting real path", e.getMessage());
    }
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode == PERMISSION_REQUEST_CODE) {
      if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        if (pendingSourcePath != null && pendingDestPath != null && pendingResult != null) {
          performImageMove(pendingSourcePath, pendingDestPath, pendingResult);
          clearPendingOperation();
          return true;
        }
      } else {
        if (pendingResult != null) {
          pendingResult.error("PERMISSION_DENIED", "Storage permission denied", null);
          clearPendingOperation();
        }
      }
      return true;
    }
    return false;
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == MANAGE_STORAGE_PERMISSION_REQUEST_CODE) {
      Log.d(TAG, "Received activity result for MANAGE_EXTERNAL_STORAGE permission");
      // Check if the permission was granted
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && Environment.isExternalStorageManager()) {
        Log.i(TAG, "MANAGE_EXTERNAL_STORAGE permission granted");
        if (pendingSourcePath != null && pendingDestPath != null && pendingResult != null) {
          performImageMove(pendingSourcePath, pendingDestPath, pendingResult);
          clearPendingOperation();
        }
      } else {
        Log.e(TAG, "MANAGE_EXTERNAL_STORAGE permission denied");
        if (pendingResult != null) {
          pendingResult.error("PERMISSION_DENIED", "All files access permission denied", null);
          clearPendingOperation();
        }
      }
      return true;
    }
    return false;
  }

  private void clearPendingOperation() {
    pendingSourcePath = null;
    pendingDestPath = null;
    pendingResult = null;
  }
}
