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

  //const apiUrl = 'https://<id>.execute-api.us-east-1.amazonaws.com/dev/upload' // API Gateway 
  const apiUrl = 'https://deov8gwhrd.execute-api.us-east-1.amazonaws.com/prod/upload'

  const formData = new FormData();
  formData.append('file', file);

  const urlWithParams = `${apiUrl}?filename=${encodeURIComponent(file.name)}`;

  uploadStatus.textContent = 'File upload in progress...';

  fetch(urlWithParams, {
    method: 'POST',
    body: formData
  })
  .then(response => {
    if (!response.ok) {
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
