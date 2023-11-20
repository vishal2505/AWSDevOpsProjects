import os
from PIL import Image

download_path = "../Sample_Images/nature.jpg"
upload_path = "../Sample_Images/nature_bw_resized.jpg"
with Image.open(download_path) as image:
    resized_image = image.resize((300, 300))
    resized_image.save(upload_path)
