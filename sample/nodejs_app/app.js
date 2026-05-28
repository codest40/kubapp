const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

// serve static files
app.use(express.static(path.join(__dirname, "public")));

// shared response helper
const buildResponse = (role, extra = {}) => ({
  status: "ok",
  role,
  service: "nodejs-app",
  message: `Welcome ${role === "admin" ? "Administrator" : "User"} 👋`,
  timestamp: new Date().toISOString(),
  ...extra
});

// health check
app.get("/api/health", (req, res) => {
  res.json(
    buildResponse("system", {
      message: "Service is healthy and running smoothly 🚀"
    })
  );
});

app.get("/api/live", (req, res) => {
  res.status(200).send("OK");
});

// USER route
app.get("/user", (req, res) => {
  res.json(
    buildResponse("user", {
      dashboard: "user-dashboard",
      features: ["view profile", "browse data", "basic access"]
    })
  );
});

// ADMIN route
app.get("/admin", (req, res) => {
  res.json(
    buildResponse("admin", {
      dashboard: "admin-console",
      features: [
        "manage users",
        "system metrics",
        "full access control",
        "logs inspection"
      ],
      warning: "Admin access granted - sensitive operations enabled ⚠️"
    })
  );
});

// fallback route (nice UX instead of blank errors)
app.get("*", (req, res) => {
  res.status(404).json({
    status: "error",
    message: "Route not found",
    availableRoutes: ["/api/health", "/user", "/admin"]
  });
});

app.listen(PORT, () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
