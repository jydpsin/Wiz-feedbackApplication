require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const customerfeedback = require('./models/customerfeedback'); // Import the User model
const app = express();
const AWS = require("aws-sdk");

app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

app.set('view engine', 'ejs');

// Initialize AWS Secrets Manager with explicit region
const secretsManager = new AWS.SecretsManager({ region: process.env.AWS_REGION });

async function connectDB() {
  try {
    console.log('Fetching MongoDB URI from Secrets Manager...');
    const data = await secretsManager.getSecretValue({ SecretId: 'my-app-secret' }).promise();
    const secrets = JSON.parse(data.SecretString);
    
    console.log('Attempting MongoDB connection...');
    await mongoose.connect(secrets.MONGO_URI + 'feedback', {
      serverSelectionTimeoutMS: 30000,
      connectTimeoutMS: 30000,
      socketTimeoutMS: 30000,
      heartbeatFrequencyMS: 1000,
      retryWrites: true,
      w: 1,
      journal: true,
      authSource: 'admin'
    });

    console.log("✅ Connected to MongoDB!");
    console.log("Current database:", mongoose.connection.db.databaseName);
    
    mongoose.set('debug', true);

    const PORT = secrets.PORT || 3006;
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });

  } catch (error) {
    console.error("Error:", error);
    process.exit(1);
  }
}

connectDB();

app.get('/', (req, res) => {
  res.render('index', { useremail: '', username: '', userfeedback: '' });
});

app.post('/generate', async (req, res) => {
  const email = req.body.useremail;
  const name = req.body.username;
  const feedback = req.body.userfeedback;

  console.log('Request Body:', req.body);
  console.log('Current database:', mongoose.connection.db.databaseName);
  console.log('Current collection:', customerfeedback.collection.name);

  try {
    const user = new customerfeedback({ useremail: email, username: name, userfeedback: feedback });
    console.log('Attempting to save document:', user);
    
    const result = await user.save();
    console.log('MongoDB Response:', result);
    console.log('Document saved to database:', mongoose.connection.db.databaseName);
    console.log('Document saved to collection:', result.collection.name);

    res.render('index', { useremail: ' ', username: ' ', userfeedback: ' ', message: 'Thank you for your feedback!' });
  } catch (error) {
    console.error('Error saving user:', error);
    console.error('Database state:', mongoose.connection.readyState);
    console.error('Current database:', mongoose.connection.db.databaseName);
    res.status(500).send('Internal Server Error');
  }
});