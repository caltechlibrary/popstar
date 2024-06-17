# The overall setup and workflow

One of the essential tasks for staff at the Caltech Library Archives is to select and scan paper materials that are in bankers boxes, and put them into archival boxes. A typical collection can consist of tens of thousands of pages of documents. The huge number of pages to be handled means that we need an efficient, simple, and fast workflow. Popstar (PhOne-based Processing SofTware for ARchives) is an experiment in creating such a workflow using commodity devices and software services.

## Example archiving project

The Caltech Archives recently accessioned materials from [Robert H. Grubbs](https://en.wikipedia.org/wiki/Robert_H._Grubbs). Grubbs was a Caltech faculty member and Nobel Prize winner in Chemistry. The hybrid collection consists of over 100 carton-size boxes of papers and thousands of digital files and emails.

<figure>
<img align="middle" src="_static/media/bankers-boxes.jpeg" width="75%">
    <figcaption>A small portion of the Robert H. Grubbs collection.</figcaption>
</figure>

Caltech Archives personnel evaluate the materials to determine which ones should be kept and digitized (we cannot keep all of the materials). The physical materials that are kept are placed in archival boxes such as the ones shown below.

<figure>
<img align="middle" src="_static/media/archival-boxes.jpeg" width="75%">
    <figcaption>Archival boxes used to store selected materials from the collection.</figcaption>
</figure>

Inside the archival boxes, paper documents are organized using manilla folders.

<figure>
<img align="middle" src="_static/media/folders-inside-boxes.jpeg" width="75%">
    <figcaption>Archival boxes used to store selected materials from the collection.</figcaption>
</figure>


## Example workflow using Popstar

Our experiment in simple, rapid scanning used a height-adjustable table (for the comfort of staff doing the work) and a large ring light positioned above the table. The ring light has a phone mount in the middle where we place an Apple iPhone with the camera facing the table surface.

<figure>
<img align="middle" src="_static/media/table-and-light.jpeg" width="75%">
    <figcaption>Our extremely basic scanning setup.</figcaption>
</figure>

We placed a gray felt pad on top of the table surface; this serves as a mat for placing document pages. The felt pad makes the surface less slippery for the papers, and also provides a more-or-less neutral background surrounding document pages so that borders may be more easily detected by later image processing steps. We also placed an "L" shape in one corner of the gray felt mat using velcro-backed cloth to provide a placement guide for document pages.

<figure>
<img align="middle" src="_static/media/example-document-scan.jpeg" width="75%">
    <figcaption>Example of an actual document image taken by our workflow software. The page is placed on a gray mat that is itself placed on the table shown in the previous photo.</figcaption>
</figure>

The scanning workflow has a modular design. The overall workflow is divided into a few separate actions:

1. Start a new destination box (one of the gray archival boxes)
2. Start a new destination folder (a manilla folder) within the current destination box
3. Take photos of documents to file into the current destination folder
4. Go to step 1

Steps 1–3 are each implemented as their own separate [_Shortcut_](https://support.apple.com/guide/shortcuts/welcome/ios) as described in the [Software](software.md) section. The first two steps above use the camera on the phone to take a picture of box or folder labels rather than document pages; the software uses optical character recognition (OCR) to transcribe any text it finds in the image and then uses the extracted text to create a folder hierarchy for the destination box and folder within the box. The third step currently does not apply OCR to document pages, because we decided it would be better to leave that to a post-processing workflow.
