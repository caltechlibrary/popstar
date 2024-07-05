# Usage

The Popstar workflow consists of the following steps:

1. Initialize a new project by running the Shortcut _Initialize Popstar for new project_.
2. Start a new destination box by running the Shortcut  _Start new destination box_.
3. Start a new destination folder by running the Shortcut  _Start new destination folder_.
4. Take photos of documents to file into the current destination folder by running the Shortcut  _Take photo of document page_.
5. Go back to step 3 when it's time to start a new destination folder.
6. Go back to step 2 when it's time to start a new destination box.
7. Go back to step 1 when it's time to start a new scanning project.

Steps 2 and 3 each use the camera on the phone to take a picture of box or folder labels rather than document pages; the software uses optical character recognition (OCR) to transcribe any text it finds in the image and then uses the extracted text to create a folder hierarchy for the destination box and folder within the box. Step 4 step currently does _not_ apply OCR to document pages, because we decided it would be better to leave that to a post-processing workflow. Instead, the third step only saves images of document pages.
