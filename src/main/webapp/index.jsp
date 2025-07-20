<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> <title>DevOps Test App - Modern View</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; /* Slightly more modern font */
            background: #eef2f7; /* Lighter, softer background */
            margin: 0;
            padding: 0;
            color: #333;
            line-height: 1.6;
        }

        header {
            background: linear-gradient(to right, #007BFF, #0056b3); /* Gradient for a modern touch */
            color: white;
            padding: 30px 0; /* More vertical padding */
            text-align: center;
            box-shadow: 0 4px 10px rgba(0,0,0,0.15); /* Stronger shadow for header */
        }

        header h1 {
            margin: 0;
            font-size: 2.8em; /* Larger title */
            letter-spacing: 1px;
        }

        header p {
            margin: 5px 0 0;
            font-size: 1.2em;
            opacity: 0.9;
        }

        .container {
            max-width: 960px; /* Slightly wider container */
            margin: 40px auto; /* More margin */
            padding: 30px; /* More padding inside */
            background: white;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1); /* Softer, larger shadow */
            border-radius: 12px; /* More rounded corners */
        }

        h2 {
            color: #0056b3; /* Darker blue for heading */
            border-bottom: 2px solid #e0e0e0; /* Subtle separator */
            padding-bottom: 10px;
            margin-top: 0;
            font-size: 2em;
        }

        h3 {
            color: #007BFF;
            font-size: 1.5em;
            margin-top: 25px;
        }

        ul {
            list-style: none; /* Remove default bullet points */
            padding: 0;
            margin: 15px 0;
        }

        ul li {
            padding: 8px 0;
            border-bottom: 1px dashed #f0f0f0; /* Dashed separator for list items */
            display: flex; /* For better alignment of icons/text if adding later */
            align-items: center;
        }

        ul li:last-child {
            border-bottom: none; /* No separator for the last item */
        }

        .highlight {
            color: #d9534f; /* A slightly more modern red */
            font-weight: bold;
        }

        .btn {
            display: inline-block;
            margin-top: 30px; /* More space above button */
            padding: 12px 28px; /* Larger button */
            background: #28a745;
            color: white;
            text-decoration: none;
            border-radius: 8px; /* More rounded button */
            font-weight: bold;
            font-size: 1.1em;
            transition: background 0.3s ease, transform 0.2s ease; /* Smooth hover effect */
        }

        .btn:hover {
            background: #218838;
            transform: translateY(-2px); /* Slight lift on hover */
        }

        .footer {
            background: #2c3e50; /* Darker footer */
            color: #ecf0f1; /* Lighter text */
            text-align: center;
            padding: 20px 0; /* More padding */
            margin-top: 50px;
            font-size: 0.85em;
            box-shadow: 0 -2px 8px rgba(0,0,0,0.1);
        }

        code {
            background: #f0f2f5; /* Lighter background for code */
            padding: 3px 8px;
            border-radius: 5px;
            font-family: 'Fira Code', 'Cascadia Code', monospace; /* Modern monospaced font suggestion */
            font-size: 0.9em;
            color: #c7254e; /* Distinct color for code */
        }

        .box {
            background: #e3f2fd; /* Lighter, softer blue for box */
            padding: 20px;
            border-left: 5px solid #007BFF; /* Thicker border */
            margin-top: 30px;
            border-radius: 8px;
            box-shadow: inset 0 0 5px rgba(0,0,0,0.05); /* Inner shadow for depth */
        }

        .box h4 {
            color: #0056b3;
            margin-top: 0;
            border-bottom: 1px dashed #c0d9ec; /* Subtle separator in box */
            padding-bottom: 8px;
        }

        .box ul {
            padding-left: 0; /* Remove padding if list-style is none */
            margin-top: 10px;
        }
    </style>
</head>
<body>

<header>
    <h1>Welcome to DevOps <br> <small>(Test Application)</small></h1>
    <p>Empowering Your Journey into Continuous Delivery</p>
</header>

<div class="container">
    <h2>🚀 DevOps & CI/CD Demo</h2>
    <p>This single-page application serves as a tangible demonstration of fundamental <strong>DevOps workflows</strong>, showcasing the integration and automation capabilities of various tools like Jenkins, Docker, and Kubernetes.</p>

    <h3>🛠 Core Tools & Technologies</h3>
    <ul>
        <li><strong class="highlight">Jenkins</strong> – The orchestrator for our robust CI/CD pipeline.</li>
        <li><strong class="highlight">Docker</strong> – Utilized for efficient application containerization.</li>
        <li><strong class="highlight">Kubernetes</strong> – Manages and scales our containerized applications.</li>
        <li><strong class="highlight">GitHub</strong> – Our primary platform for source code control and collaboration.</li>
    </ul>

    <h3>📦 Application Deployment Details</h3>
    <p><strong>Docker Image:</strong> <code>sunrisersheroic/maven-web-app:1.0.13</code></p>
    <p><strong>Kubernetes Deployment:</strong> This application is deployed using a Kubernetes <code>Deployment</code> managed by a <code>LoadBalancer Service</code> for external access.</p>

    <div class="box">
        <h4>📌 Integrated DevOps Ecosystem</h4>
        <ul>
            <li>**Maven** – Powers the build process to generate the WAR artifact.</li>
            <li>**SonarQube** – Ensures code quality and security through static analysis.</li>
            <li>**Nexus** – Serves as our central artifact repository.</li>
            <li>**Jenkins** – Automates the entire build, test, and deployment lifecycle.</li>
        </ul>
    </div>

    <a href="https://facebook.com/groups/thejavatemple" class="btn" target="_blank">Join Our DevOps Community</a>
</div>

<div class="footer">
    &copy; 2025 DevOps Test App | Crafted for DevOps Learning Enthusiasts
</div>

</body>
</html>
