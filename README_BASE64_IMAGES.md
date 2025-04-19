# Base64 Image Implementation Guide

This guide explains how to handle images in the Furniture App using Base64 encoding. This approach converts images to Base64 strings and stores them in Firestore, making it easier to manage images without needing a separate storage service.

## How Base64 Image Handling Works

1. Images are converted to Base64 strings using the `fileToBase64` method
2. The Base64 strings are stored in Firestore in the `product_images` collection
3. When displaying images, the Base64 strings are retrieved and converted back to image data

## How to Upload Images

### Using the ProductModel Helper

```dart
// Get image files from device or camera
List<File> imageFiles = [/* your image files */];

// Upload images and get image IDs
List<String> imageIds = await ProductModel.uploadProductImages(imageFiles);

// Use these IDs when creating or updating a product
ProductModel product = ProductModel(
  // other fields...
  imageUrls: imageIds,
  // other fields...
);
```

### Using FirebaseService Directly

```dart
final firebaseService = FirebaseService();

// Convert a single file to Base64
String base64String = await firebaseService.fileToBase64(imageFile);

// Upload the Base64 string to Firestore
String imageId = await firebaseService.uploadBase64Image(base64String, 'product_images');

// Upload multiple image files
List<String> imageIds = await firebaseService.uploadProductImagesFromFiles(imageFiles);
```

## How to Display Images

### Using the FirebaseBase64Image Widget

```dart
// Display a single image using its Firestore document ID
FirebaseBase64Image(
  imageId: product.imageUrls.first,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
  collectionName: 'product_images',
)
```

### Using ProductModel Helpers

```dart
// Get the first image as a File object
File? imageFile = await product.getFirstImage();

// Display the image if available
if (imageFile != null) {
  Image.file(
    imageFile,
    width: 100,
    height: 100,
    fit: BoxFit.cover,
  )
}

// Get all product images as File objects
List<File> imageFiles = await product.getImageFiles();
```

## Troubleshooting

If you encounter issues with image loading:

1. Check that the image ID exists in the Firestore `product_images` collection
2. Verify the image was properly converted to Base64 (not truncated or corrupted)
3. Ensure the device has enough memory to handle the Base64 decoded images
4. For large images, consider using the chunked upload/download functionality

## Best Practices

1. Keep image sizes reasonable (compress before converting to Base64)
2. Use the caching functionality in FirebaseBase64Image to improve performance
3. Consider lazy loading images to reduce memory usage
4. For lists of products, use thumbnails rather than full-size images 