FROM --platform=linux/amd64 node:16

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./

RUN npm install

# Bundle app source
COPY . .

# Expose port
EXPOSE 3006

# Start the app
CMD [ "node", "app.js" ]