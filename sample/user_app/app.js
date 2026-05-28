const express = require("express");
const app = express();

const PORT = 3000;

const html = `
<!DOCTYPE html>
<html>
<head>
  <title>User App</title>
  <style>
    body { font-family: Arial; text-align: center; margin-top: 50px; }
    .box { padding: 20px; border-radius: 10px; background: #e3f2fd; display: inline-block; }
  </style>
</head>
<body>
  <div class="box">
    <h1>👤 USER APP</h1>
    <p>Status: OK</p>
  </div>
</body>
</html>
`;

// Root
app.get("/", (req, res) => res.send(html));

// Explicit /user route (for ingress path testing)
app.get("/user", (req, res) => res.send(html));

// Health checks
app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy", service: "user" });
});

app.get("/live", (req, res) => {
  res.status(200).json({ status: "alive", service: "user" });
});

app.listen(PORT, () => {
  console.log(`User app running on port ${PORT}`);
});

