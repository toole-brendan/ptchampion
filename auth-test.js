// Script to test authentication against the deployed server
const axios = require('axios');

const API_URL = 'http://23.20.242.95:3000/api';
const CREDS = {
  username: 'test-user-' + Math.floor(Math.random() * 1000),
  password: 'password123'
};

async function testAuth() {
  console.log('Testing authentication with credentials:', CREDS);
  
  try {
    // Step 1: Register a new user
    console.log('\n--- Registering new user ---');
    const registerRes = await axios.post(`${API_URL}/register`, CREDS);
    console.log('Registration successful:', registerRes.status, registerRes.statusText);
    console.log('User data:', JSON.stringify(registerRes.data, null, 2).slice(0, 200) + '...');
    
    // Step 2: Logout (to ensure fresh login)
    console.log('\n--- Logging out ---');
    await axios.post(`${API_URL}/logout`);
    console.log('Logout successful');
    
    // Step 3: Login with the newly created user
    console.log('\n--- Logging in ---');
    const loginRes = await axios.post(`${API_URL}/login`, CREDS);
    console.log('Login successful:', loginRes.status, loginRes.statusText);
    console.log('Login response:', JSON.stringify(loginRes.data, null, 2).slice(0, 200) + '...');
    
    // Step 4: Get user data (should be authenticated)
    console.log('\n--- Getting user data ---');
    // Use the cookie from the login response
    const userRes = await axios.get(`${API_URL}/user`, {
      withCredentials: true,
      headers: {
        Cookie: loginRes.headers['set-cookie']?.join('; ')
      }
    });
    console.log('User data request successful:', userRes.status, userRes.statusText);
    console.log('User data:', JSON.stringify(userRes.data, null, 2));
    
    console.log('\n✅ Authentication test completed successfully!');
  } catch (error) {
    console.error('\n❌ Authentication test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Response:', error.response.data);
    } else {
      console.error(error.message);
    }
  }
}

testAuth();
