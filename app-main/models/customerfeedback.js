const { text } = require('body-parser');
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  useremail: { type: String, required: true },
  username: { type: String, required: true },
  userfeedback: { type : String, required: true}
});

// Define the model and specify the collection name
const customerfeedback = mongoose.model('customerfeedback', userSchema, 'customerfeedback');

module.exports = customerfeedback;

