const fs = require('fs');
const env = fs.readFileSync('.env', 'utf8');
const url = env.match(/SUPABASE_URL=([^\s]+)/)[1];
const key = env.match(/SUPABASE_SERVICE_ROLE_KEY=([^\s]+)/)[1];

async function checkUser() {
  const res = await fetch(`${url}/rest/v1/authorized_users?phone=eq.605676002`, {
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`
    }
  });
  const data = await res.json();
  console.log('USUARIO 605676002:', data);
}

checkUser();
