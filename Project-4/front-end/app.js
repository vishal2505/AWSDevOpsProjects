document.getElementById('file-input').addEventListener('change', getFileDetails);

function getFileDetails(event) {
  const fileInput = document.getElementById('file-input');
  const fileDetails = document.getElementById('file-details');

  while (fileDetails.firstChild) {
    fileDetails.removeChild(fileDetails.firstChild);
  }

  for (const file of fileInput.files) {
    const fileInfo = document.createElement('p');
    fileInfo.textContent = `File name: ${file.name}, Size: ${file.size} bytes`;
    fileDetails.appendChild(fileInfo);
  }
}

document.getElementById('submit-btn').addEventListener('click', uploadFile);

function uploadFile(event) {

  const fileInput = document.getElementById('file-input');
  const uploadStatus = document.getElementById('upload-status');

  if (fileInput.files.length === 0) {
    alert('Please select a file before submitting.');
    return;
  }
  const file = fileInput.files[0];
  // Check file type (text or image)
  const fileType = file.type.split('/')[0]

  const bucket = 'user-content-bucket-9001';

  const formData = new FormData();
  formData.append('file', file);
  // Add additional parameters based on file type
  if (fileType === 'text') {
    formData.append('mimeType', 'text/plain'); // Set content type for text files
  } else if (fileType === 'image') {
    // Set content type based on image format (e.g., image/jpeg)
    formData.append('mimeType', file.type);
  }

  const filename = `${encodeURIComponent(file.name)}`;

  const apiUrl = `https://9qxyb7ppvj.execute-api.us-east-1.amazonaws.com/prod/${bucket}/${filename}`
  console.log("API URL: " + apiUrl)

  uploadStatus.textContent = 'File upload in progress...';

  console.log(formData.entries())

  var apigClient = apigClientFactory.newClient({
    defaultContentType: 'multipart/form-data',
    defaultAcceptType: '*/*'
  });
  var params = { 
    bucket: bucket,
    filename: filename,
    'Content-Type': 'multipart/form-data',
    'Accept': '*/*'
  };
  var additionalParams = {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  };

  // fetch(apiUrl, {
  //   method: 'PUT',
  //   body: formData
  // })
  apigClient.bucketFilenamePut(params, formData, additionalParams)
  .then(response => {
    if (!response.ok) {
      console.log(response);
      throw new Error('Network response was not ok.');
    }
    return response.json();
  })
  .then(data => {
    const uploadStatus = document.getElementById('upload-status');
    uploadStatus.textContent = `File upload successful: ${file.name}`;
    console.log('File upload successful:', data);
  })
  .catch(error => {
    const uploadStatus = document.getElementById('upload-status');
    uploadStatus.textContent = `There was a problem with the file upload: ${error.message}`;
    console.error('There was a problem with the file upload:', error);
  });
}

document.getElementById('reset-btn').addEventListener('click', function () {
  const fileDetails = document.getElementById('file-details');
  const uploadStatus = document.getElementById('upload-status');

  while (fileDetails.firstChild) {
    fileDetails.removeChild(fileDetails.firstChild);
  }

  uploadStatus.textContent = '';
});
