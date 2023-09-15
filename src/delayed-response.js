const http = require('http');
const PORT = 1803;
const delayMs = 500;

const server = http.createServer((req, res) => {
  setTimeout(() => {
    res.writeHead(200);
    res.end();
	console.log(`Server is responding on port ${PORT}: ${new Date()}`);
  }, delayMs);
});

server.listen(PORT, () => {
  console.log(`Server is listening on port ${PORT}.  Started: ${new Date()}`);
});
