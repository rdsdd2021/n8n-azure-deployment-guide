// Create Neon Database using API
const https = require('https');
const fs = require('fs');

async function createNeonProject() {
  try {
    // Read the API key from the Neon CLI credentials
    const credentialsPath = process.env.HOME || process.env.USERPROFILE;
    const configPath = `${credentialsPath}/.config/neonctl/credentials.json`;

    console.log('Creating Neon database project...');
    console.log('Please go to https://console.neon.tech/app/projects');
    console.log('1. Click "New Project"');
    console.log('2. Name it "n8n-azure-database"');
    console.log('3. Choose AWS us-east-1 region');
    console.log('4. Click "Create Project"');
    console.log('5. Copy the connection string and run this script with the project ID');

    if (process.argv[2]) {
      const projectId = process.argv[2];
      console.log(`\nYour project ID: ${projectId}`);
      console.log('Connection string format:');
      console.log(`postgresql://[user]:[password]@[host]/[database]`);
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}

createNeonProject();