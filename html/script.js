// Helper funkce pro odesílání dat do Lua
async function post(eventName, data = {}) {
    try {
        const response = await fetch(`https://aprts_multijob/${eventName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (e) {
        console.error(`Error in post event [${eventName}]: ${e}`);
        return null;
    }
}

const container = document.getElementById('container');
const closeButton = document.getElementById('close-button');

// Menu panely
const jobMenu = document.getElementById('job-menu');
const bossMenu = document.getElementById('boss-menu');

// Globální proměnné pro uchování dat
let currentJobName = '';

// Schování NUI
function closeNUI() {
    container.classList.add('hidden');
    post('close');
}

closeButton.addEventListener('click', closeNUI);
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeNUI();
    }
});


// ==================== JOB MENU LOGIC ====================
const myJobsList = document.getElementById('my-jobs-list');
const currentJobLabel = document.getElementById('current-job-label');

function populateMyJobs(jobs, activeJob, activeJobLabel) {
    myJobsList.innerHTML = '';
    currentJobName = activeJob;
    currentJobLabel.textContent = activeJobLabel || 'Nezaměstnaný';

    if (!jobs || jobs.length === 0) {
        myJobsList.innerHTML = '<p>Nemáte žádné další práce.</p>';
        return;
    }

    jobs.forEach(job => {
        const isActive = job.name === activeJob;
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div class="item-info">
                <span>${job.label} (Hodnost: ${job.grade})</span>
            </div>
            <div class="item-actions">
                <button class="set-active-btn" data-job-name="${job.name}" ${isActive ? 'disabled' : ''}>Aktivovat</button>
                <button class="quit-job-btn fire-btn" data-job-name="${job.name}">Odejít</button>
            </div>
        `;
        myJobsList.appendChild(item);
    });

    // Event Listeners pro nově vytvořená tlačítka
    document.querySelectorAll('.set-active-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            post('setActiveJob', { jobName: e.target.dataset.jobName });
            closeNUI();
        });
    });

    document.querySelectorAll('.quit-job-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            if (confirm(`Opravdu chcete opustit práci ${e.target.dataset.jobName}?`)) {
                post('quitJob', { jobName: e.target.dataset.jobName });
                closeNUI();
            }
        });
    });
}

// ==================== BOSS MENU LOGIC ====================
const employeesList = document.getElementById('employees-list');
let bossJobName = '';

// Tab switching
document.querySelectorAll('.tab-button').forEach(button => {
    button.addEventListener('click', () => {
        document.querySelectorAll('.tab-button').forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');
        
        const tabId = button.dataset.tab + '-tab';
        document.querySelectorAll('.tab-content').forEach(tab => tab.classList.add('hidden'));
        document.getElementById(tabId).classList.remove('hidden');
    });
});


function populateEmployees(employees, jobName) {
    bossJobName = jobName;
    employeesList.innerHTML = '';

    if (!employees || employees.length === 0) {
        employeesList.innerHTML = '<p>Nemáte žádné zaměstnance.</p>';
        return;
    }

    employees.forEach(emp => {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <div class="item-info">
                <span>${emp.name}</span>
                <span>Hodnost: ${emp.grade}</span>
            </div>
            <div class="item-actions">
                <button class="promote-btn" data-charid="${emp.charid}" data-current-grade="${emp.grade}">Povýšit/Degradovat</button>
                <button class="fire-btn" data-charid="${emp.charid}">Propustit</button>
            </div>
        `;
        employeesList.appendChild(item);
    });

    // Event Listeners
    document.querySelectorAll('.promote-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const charid = e.target.dataset.charid;
            const currentGrade = e.target.dataset.currentGrade;
            const newGrade = prompt(`Zadejte novou hodnost pro zaměstnance (aktuální: ${currentGrade}):`, currentGrade);

            if (newGrade !== null && !isNaN(newGrade) && newGrade >= 0) {
                post('setGrade', { 
                    charid: parseInt(charid), 
                    newGrade: parseInt(newGrade),
                    jobName: bossJobName 
                });
                closeNUI();
            } else if (newGrade !== null) {
                alert('Zadejte prosím platné číslo.');
            }
        });
    });

    document.querySelectorAll('.fire-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            if (confirm('Opravdu chcete propustit tohoto zaměstnance?')) {
                const charid = e.target.dataset.charid;
                post('fireEmployee', { 
                    charid: parseInt(charid),
                    jobName: bossJobName
                });
                closeNUI();
            }
        });
    });
}

document.getElementById('hire-player-btn').addEventListener('click', () => {
    post('hirePlayer', { jobName: bossJobName });
    closeNUI();
});


// ==================== MAIN EVENT LISTENER ====================
window.addEventListener('message', (event) => {
    const data = event.data;
    const action = data.action;

    switch (action) {
        case 'openJobMenu':
            document.getElementById('menu-title').textContent = "Správa zaměstnání";
            bossMenu.classList.add('hidden');
            jobMenu.classList.remove('hidden');
            populateMyJobs(data.jobs, data.currentJob, data.currentJobLabel);
            container.classList.remove('hidden');
            break;
        
        case 'openBossMenu':
            document.getElementById('menu-title').textContent = `Boss Menu (${data.jobLabel})`;
            jobMenu.classList.add('hidden');
            bossMenu.classList.remove('hidden');
            // Reset to default tab
            document.querySelector('.tab-button[data-tab="employees"]').click();
            populateEmployees(data.employees, data.jobName);
            container.classList.remove('hidden');
            break;
    }
});