var region = 'us-east-1';
const identityPoolId = 'us-east-1:dc52514a-c6f7-440b-a8f5-b7d71a9781f5'; // Cognito Identity Pool ID
const cognitoIdentityProviderName = 'accounts.google.com'; // Cognito Identity Provider name - Google, facebook ,Twitter
const user_content_bucket = 'image-storage-bucket-7001';  // User Content Bucket

// Initialize Google Sign-in
function onSignIn(googleToken) {
    // Pass the Google identity token upon successful Google Sign In
    credentialExchange(googleToken);
}

// Getting temporary credentials from Cognito using google Id token
function credentialExchange(googleToken) {
    // Decoding token to see detials
    console.log("Creating decoded token...");
    const googleTokenDecoded = parseJwt(googleToken.credential);
    
    // Displaying details on the browser console
    console.log("ID: " + googleTokenDecoded.sub);
    console.log('Full Name: ' + googleTokenDecoded.name);
    console.log("Email: " + googleTokenDecoded.email);
    
    if (googleTokenDecoded['sub']) {
      
      // Exchanging credentials from Cognito using Google ID Token
      console.log("Exchanging Google Token for AWS credentials...");
      AWS.config.region = 'us-east-1'; 
      AWS.config.credentials = new AWS.CognitoIdentityCredentials({
        IdentityPoolId: identityPoolId,
        Logins: {
            [cognitoIdentityProviderName] : googleToken.credential
        }
      });
  
      // Getting AWS Temporary Credentials
      AWS.config.credentials.get(function(err) {
        if (!err) {
          console.log('Exchanged to Cognito Identity Id: ' + AWS.config.credentials.identityId);          
          // Getting file list from S3 using temporary credentials
          refreshFileList(user_content_bucket);
        } else {
          console.log('ERROR: ' + err);
        }
      });  
    } else {
      console.log('User not logged in!');
    }
  }

// AWS.config.update({
//     region:region,
//     credentials: new AWS.Credentials(accessKeyID, secretAccessKey)
// })

function refreshFileList(bucketname){
    // Creating AWS S3 instance using Javascript SDK
    var s3 = new AWS.S3()
    var tableBody = document.querySelector("#fileTable tbody");
    tableBody.innerHTML = "";

    s3.listObjectsV2({Bucket:bucketname}, (err,data) => {
        if (err){
            console.log("Error fetching file list", err)
        } else {
            data.Contents.forEach((object) => {
                var fileRow = document.createElement('tr');

                // Getting File Name
                var fileNameCell = document.createElement('td');
                fileNameCell.textContent = object.Key;
                fileRow.appendChild(fileNameCell);
                
                // Getting File Size
                var fileSizeCell = document.createElement('td');
                fileSizeCell.textContent = object.Size;
                fileRow.appendChild(fileSizeCell);

                // Getting Presigned URL for Download link
                var downloadCell = document.createElement('td');
                var downloadLink = document.createElement('a');
                downloadLink.href = s3.getSignedUrl("getObject", {
                    Bucket: bucketname,
                    Key: object.Key
                });
                downloadLink.textContent = "Download";
                downloadCell.appendChild(downloadLink);
                fileRow.appendChild(downloadCell);

                // Delete button - OnClick call deleteFile() method
                var deleteCell = document.createElement('td');
                var deleteButton = document.createElement('button');
                deleteButton.textContent = "Delete";
                deleteButton.addEventListener('click', () => {
                    deleteFile(bucketname, object.Key);
                })
                deleteCell.appendChild(deleteButton);
                fileRow.appendChild(deleteCell);

                // Adding row for the object in the table
                tableBody.appendChild(fileRow);
            });
        }
    })
}

// Method for uploading files to S3
function uploadFiles(){
    var s3 = new AWS.S3()
    let files = document.getElementById('fileInput').files;
    console.log(files);

    for(var fileIter=0;fileIter<files.length;fileIter++){
        var file = files[fileIter];
        console.log(file.name);
        var params = {
            Bucket:user_content_bucket,
            Key:file.name,
            Body:file
        }
        s3.upload(params, (err,data) => {
            if (err){
                console.log("Error uploading the file", err);
            } else {
                console.log("File Uploaded");

                // Creating Alert for upload-success
                const uploadAlertEl = document.getElementById('upload-success');
                uploadAlertEl.innerText = `File "${file.name}" uploaded successfully!`;
                uploadAlertEl.classList.remove('d-none'); // Show the alert
                // Adding timeout for automatic dismissal
                setTimeout(() => uploadAlertEl.classList.add('d-none'), 3000);

                refreshFileList(user_content_bucket);
            }
        })
    }
}

// Method for deleting files from S3
function deleteFile(bucketname,key){ 
    var s3 = new AWS.S3()
    var params = {
        Bucket: bucketname,
        Key:key
    }
    s3.deleteObject(params, (err,data) => {
        if (err){
            console.log("Error deleteing the file", err);
        } else {
            console.log("File deleted successfully");

            // Creating Alert for delete-success
            const deleteAlertEl = document.getElementById('delete-success');
            deleteAlertEl.innerText = `File "${key}" deleted successfully!`;
            deleteAlertEl.classList.remove('d-none');
            // Adding timeout for automatic dismissal
            setTimeout(() => deleteAlertEl.classList.add('d-none'), 3000);

            refreshFileList(bucketname);
        }
    })
}

// Logout button - onClick() AWS Temp credentials will be deleted and fileTable will be empty
function logout() {
    const emptyCredentials = {
        accessKeyId: null,
        secretAccessKey: null,
        sessionToken: null
    };
    AWS.config.credentials = new AWS.Credentials(emptyCredentials);

    const fileTable = document.getElementById('fileTable');
    fileTable.style.display = 'none';
}

function getHtml(template) {
    return template.join('\n');
  }

// A utility function to decode the google token
function parseJwt(token) {
    var base64Url = token.split('.')[1];
    var base64 = base64Url.replace('-', '+').replace('_', '/');
    var plain_token = JSON.parse(window.atob(base64));
    return plain_token;
};