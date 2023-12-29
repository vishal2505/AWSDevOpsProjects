from datetime import datetime
import uuid
from flask import Flask, render_template, request, redirect, url_for
import boto3  # Import Boto3 for DynamoDB
from boto3.dynamodb.conditions import Key 

app = Flask(__name__)

# Configure DynamoDB 
# No need to provide acess key and secret access key 
# instead we'll be attaching an IAM role with appropriate DynamoDB access permissions to our ECS task.

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

# Define routes
# Route for the home page
@app.route('/')
def index():
    # Retrieve posts from DynamoDB
    posts = get_posts_from_dynamodb()
    print(posts)
    return render_template('index.html', posts=posts)

# Route for getting the post details based on the post_id
@app.route('/posts/<post_id>')
def view_post(post_id):
    # Retrieve post details from DynamoDB
    post = get_post_by_id(post_id)
    print(post)
    return render_template('posts/view.html', post=post)

# Route for creating new post
@app.route('/posts/new', methods=['GET', 'POST'])
def new_post():
    if request.method == 'GET':
        return render_template('posts/new.html')
    else:
        title = request.form['title']
        author = request.form['author']
        content = request.form['content']
        create_post(title, author, content)
        return redirect(url_for('index'))

# Route for updating exiting post   
@app.route('/posts/<post_id>/edit', methods=['GET', 'POST'])
def edit_post(post_id):
    post = get_post_by_id(post_id)  # Use your existing function
    if request.method == 'GET':
        return render_template('posts/edit.html', post=post)
    else:
        title = request.form['title']
        content = request.form['content']
        author = request.form['author']
        print("Updating for author: " + author)
        update_post(post_id, title, author, content)
        return redirect(url_for('view_post', post_id=post_id))

# Route for deleting exiting post
@app.route('/posts/<post_id>/delete', methods=['GET', 'POST'])
def delete_post(post_id):
    author = request.args.get('author')
    print("Author: " + author)
    delete_post(post_id, author)
    print("Post delete successfully.")
    return redirect(url_for('index'))

# Functions for interacting with DynamoDB
def get_posts_from_dynamodb():
    table = dynamodb.Table('BlogPosts')

    response = table.scan()  # Retrieve all items from the table
    posts = response['Items']

    while 'LastEvaluatedKey' in response:  # Handle pagination
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        posts.extend(response['Items'])

    return posts

# Function for getting post details by post_id
def get_post_by_id(post_id):
    print("post id: ", post_id)
    table = dynamodb.Table('BlogPosts')

    try:
        response = table.query(KeyConditionExpression=Key('post_id').eq(post_id))
        #response = table.get_item(Key={'post_id': post_id})  # Get the specific item
        post = response['Items'][0]
        return post
    except KeyError:
        return None

# Function for creating new post
def create_post(title, author, content):
    table = dynamodb.Table('BlogPosts')

    new_post = {
        'post_id': generate_unique_id(),
        'title': title,
        'author': author,
        'content': content,
        'timestamp': datetime.utcnow().isoformat(),  # Using UTC timestamp
    }

    table.put_item(Item=new_post)

# Function for updating exiting post
def update_post(post_id, title, author, content):
    table = dynamodb.Table('BlogPosts')

    updated_post = {
        'Key': {'post_id': post_id, 'author': author},
        'UpdateExpression': 'SET title = :title, content = :content',
        'ExpressionAttributeValues': {
            ':title': title,
            ':content': content,
        },
    }
    print(updated_post)
    response = table.update_item(**updated_post)
    print(response)
    print("Table udpated successfully")

# Function for Deleitng exiting post by post_id and author - Key attributes
def delete_post(post_id, author):
    table = dynamodb.Table('BlogPosts')

    table.delete_item(Key={'post_id': post_id, 'author':author})

def generate_unique_id():
    unique_id = str(uuid.uuid4())  # Generating a universally unique identifier
    return unique_id

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
