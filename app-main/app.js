require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const customerfeedback = require('./models/customerfeedback'); // Import the User model
const app = express();
const AWS = require("aws-sdk");
const secretsManager = new AWS.SecretsManager({ region: "eu-central-1" });

app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

app.set('view engine', 'ejs');

// Get the secret value from AWS Secrets Manager
async function getSecrets() {
  try {
    const data = await secretsManager.getSecretValue({ SecretId: "my-app-secret" }).promise();
    const secrets = JSON.parse(data.SecretString);
    
    const mongoURI = secrets.MONGO_URI;
    process.env.PORT = secrets.PORT;

    // Use environment variable for MongoDB connection string
    if (!mongoURI) {
      console.error('Error: MONGO_URI is not defined in the environment variables.');
      process.exit(1);
    }

    mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000,
      connectTimeoutMS: 30000
    }).then(() => {
      console.log("✅ Connected to MongoDB with authentication!");
    }).catch((err) => {
      console.error("❌ MongoDB Connection Error:", err);
    });

    // Enable Mongoose debug mode
    mongoose.set('debug', true);

    const PORT = process.env.PORT || 3006;
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });

  } catch (error) {
    console.error("Error fetching secrets:", error);
  }
}

getSecrets();

app.get('/', (req, res) => {
  res.render('index', { useremail: '', username: '', userfeedback: '' });
});

app.post('/generate', async (req, res) => {
  const email = req.body.useremail;
  const name = req.body.username;
  const feedback = req.body.userfeedback;

  // Log the request body to debug
  console.log('Request Body:', req.body);

  try {
    const user = new customerfeedback({ useremail: email, username: name, userfeedback: feedback });
    await user.save();
    console.log('User saved:', user);
    res.render('index', { useremail: ' ', username: ' ', userfeedback: ' ', message: 'Thank you for your feedback!' });
  } catch (error) {
    console.error('Error saving user:', error);
    res.status(500).send('Internal Server Error');
  }
});