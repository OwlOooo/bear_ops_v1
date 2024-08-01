const express = require('express');
const http = require('http');
const path = require('path');
const WebSocket = require('ws');
const { exec } = require('child_process');
const fs = require('fs').promises;
const app = express();
const server = http.createServer(app); // 创建 HTTP 服务器

// 设置静态文件中间件
app.use(express.static(path.join(__dirname, 'public')));
// 添加请求体解析日志
app.use((req, res, next) => {
  if (req.method === 'POST') {
    console.log('Request body:', req.body);
  }
  next();
});
app.use(express.json());
// 定义路由，这里是根路径的响应
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 创建 WebSocket 服务器
const wss = new WebSocket.Server({ server });

// WebSocket 连接处理
wss.on('connection', function connection(ws, req) {
  const userName = req.url.split('/')[2]; // 解析出路径参数中的 userName
  console.log(`WebSocket client connected for user: ${userName}`);
  ws.send(`连接成功`);

  ws.on('message', function incoming(message) {
    console.log(`Received message from ${userName}: ${message}`);
    // 在这里可以处理接收到的消息，然后将响应发送回客户端
    ws.send(`Server received: ${message}`);
  });

  // 可以在连接关闭时进行清理操作
  ws.on('close', function close() {
    console.log(`WebSocket client disconnected for user: ${userName}`);
  });
});

// 封装向所有客户端发送消息的函数
function broadcastMessage(message) {
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}
const COLOR = "<span style='color:#9100ff'>";
const END_COLOR = "</span>";

// 组合成一条完整的命令
function formatCommand(command, description) {
  return `echo "${COLOR}${description} ${END_COLOR}" && ${command}`;
}
// 封装执行命令的函数
function executeCommands(projectName) {
  const shellMap = new Map([
    ["加载环境变量配置", "source /etc/profile"],
    ["进入项目根目录", `cd /project/${projectName}`],
    ["查看当前目录", "pwd"],
    ["拉取代码", "git pull"],
    ["执行docker脚本", "bash docker.sh"],
    ["删除构建缓存对象", "docker builder prune -f"],
    ["删除未使用的镜像", "docker image prune -f"],
    ["删除未使用的数据卷", "docker volume prune -f"],
    ["删除未使用的网络", "docker network prune -f"]
  ]);



  // 生成完整的命令
  const commands = Array.from(shellMap.entries())
    .map(([description, command]) => formatCommand(command, description))
    .join(' && ');

  console.log(`执行命令: ${commands}`);
  const startTime = Date.now(); // 记录开始时间

  const childProcess = exec(commands, { shell: '/bin/bash' });

  let stdoutBuffer = '';
  let stderrBuffer = '';

  // 监听子进程的 stdout 输出
  childProcess.stdout.on('data', (data) => {
    stdoutBuffer += data.toString();
    let lines = stdoutBuffer.split('\n');
    stdoutBuffer = lines.pop(); // 保留不完整的行
    lines.forEach(line => {
      broadcastMessage(line);
    });
  });

  // 监听子进程的 stderr 输出
  childProcess.stderr.on('data', (data) => {
    stderrBuffer += data.toString();
    let lines = stderrBuffer.split('\n');
    stderrBuffer = lines.pop(); // 保留不完整的行
    lines.forEach(line => {
      broadcastMessage(line);
    });
  });

  // 监听命令执行结束事件
  childProcess.on('close', (code) => {
    const endTime = Date.now(); // 记录结束时间
    const durationSeconds = (endTime - startTime) / 1000; // 计算执行时间，单位为秒

    if (stdoutBuffer.length > 0) {
      broadcastMessage(stdoutBuffer); // 发送剩余的部分
    }
    if (stderrBuffer.length > 0) {
      broadcastMessage(stderrBuffer); // 发送剩余的部分
    }

    if (code === 0) {
      console.log(`命令执行成功`);
      broadcastMessage(`命令执行成功，执行时间：${durationSeconds.toFixed(2)} 秒`);
    } else {
      console.error(`命令执行失败，退出码：${code}`);
      broadcastMessage(`命令执行失败，退出码：${code}`);
    }
  });
}


// 添加 GET 方法处理 /api/push 路径
app.get('/api/push', (req, res) => {
  const { userName, projectName } = req.query;
  if (!userName || !projectName) {
    res.status(400).send('用户名和项目名是必填参数');
    return;
  }
  res.send('指令已发送...');
  executeCommands(projectName);
});

const projectJsonPath = path.join(__dirname, 'project.json');

// 获取项目列表
app.get('/api/fetchProjects', async (req, res) => {
  try {
    const data = await fs.readFile(projectJsonPath, 'utf8');
    const projects = JSON.parse(data).projects;
    res.json(projects);
  } catch (err) {
    console.error('读取 project.json 文件出错:', err);
    res.status(500).send('读取项目数据出错');
  }
});

// 保存项目列表
app.post('/api/saveProjects', async (req, res) => {
  console.log('Received POST request to /api/saveProjects');
  console.log('Request body:', req.body);

  try {
    if (!req.body || !req.body.projects) {
      return res.status(400).json({ error: 'Invalid request body. Expected { projects: [...] }' });
    }

    let { projects } = req.body;

    // 验证 projects 是否为数组
    if (!Array.isArray(projects)) {
      return res.status(400).json({ error: 'Invalid projects data. Expected an array.' });
    }
    projects = projects.map(project => project.replace(/_/g, '-'));
    // 将项目列表写入文件
    await fs.writeFile(projectJsonPath, JSON.stringify({ projects }, null, 2), 'utf8');

    console.log('Projects saved successfully');
    res.json({ message: 'Projects saved successfully' });
  } catch (error) {
    console.error('Error saving projects:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});
// 启动服务器
const PORT = process.env.PORT || 8976;
server.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
