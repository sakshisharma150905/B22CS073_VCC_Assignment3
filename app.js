// app.js - A simple Express app that can be used to demonstrate auto-scaling
const express = require('express');
const os = require('os');
const app = express();
const port = process.env.PORT || 3000;

// Middleware to simulate CPU load
const simulateLoad = (req, res, next) => {
  if (req.query.load === 'high') {
    console.log('Simulating high CPU load...');
    const startTime = Date.now();
    // Busy loop to consume CPU
    while (Date.now() - startTime < 5000) {
      // Do nothing, just consume CPU
      for (let i = 0; i < 1000000; i++) {
        Math.sqrt(i);
      }
    }
  }
  next();
};

app.use(simulateLoad);

// Main route
app.get('/', (req, res) => {
  const memoryUsage = process.memoryUsage();
  const totalMemory = os.totalmem();
  const freeMemory = os.freemem();
  const usedMemory = totalMemory - freeMemory;
  
  const systemInfo = {
    hostname: os.hostname(),
    platform: os.platform(),
    architecture: os.arch(),
    cpus: os.cpus().length,
    uptime: os.uptime(),
    loadAverage: os.loadavg(),
    memoryUsage: {
      total: `${Math.round(totalMemory / 1024 / 1024)} MB`,
      free: `${Math.round(freeMemory / 1024 / 1024)} MB`,
      used: `${Math.round(usedMemory / 1024 / 1024)} MB`,
      usedPercentage: `${Math.round((usedMemory / totalMemory) * 100)}%`,
      rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
      heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`
    }
  };
  
  res.json({
    message: 'Auto-Scaling Demo Application',
    environment: process.env.NODE_ENV || 'development',
    systemInfo
  });
});

// Route to generate high CPU load
app.get('/stress', (req, res) => {
  const duration = parseInt(req.query.duration) || 30;
  const startTime = Date.now();
  
  console.log(`Generating CPU stress for ${duration} seconds...`);
  
  // Function to consume CPU
  const consumeCPU = () => {
    const now = Date.now();
    if (now - startTime < duration * 1000) {
      // Perform heavy calculations
      for (let i = 0; i < 10000000; i++) {
        Math.sqrt(i);
      }
      setImmediate(consumeCPU);
    } else {
      res.json({
        message: 'Stress test completed',
        duration: `${duration} seconds`
      });
    }
  };
  
  consumeCPU();
});

// Memory consumption route
app.get('/memory', (req, res) => {
  const sizeInMB = parseInt(req.query.size) || 100;
  const duration = parseInt(req.query.duration) || 60;
  
  console.log(`Allocating ${sizeInMB}MB of memory for ${duration} seconds...`);
  
  // Allocate memory
  const buffers = [];
  const megabyte = 1024 * 1024;
  
  for (let i = 0; i < sizeInMB; i++) {
    buffers.push(Buffer.alloc(megabyte));
  }
  
  // Set timeout to release memory
  setTimeout(() => {
    buffers.length = 0;
    global.gc && global.gc(); // Try to garbage collect if possible
  }, duration * 1000);
  
  res.json({
    message: 'Memory allocation in progress',
    allocated: `${sizeInMB} MB`,
    duration: `${duration} seconds`
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Demo application listening on port ${port}`);
});
