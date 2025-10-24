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

// Schování NUI
function closeNUI() {
    container.classList.add('hidden');
    container.style.top = '50%';
    container.style.left = '50%';
    container.style.transform = 'translate(-50%, -50%)';
    post('close');
}

closeButton.addEventListener('click', closeNUI);
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Zavřeme modal, pokud je otevřený, jinak zavřeme hlavní okno
        if (!confirmModal.classList.contains('hidden')) {
            hideConfirm();
        } else {
            closeNUI();
        }
    }
});

// ==================== VLASTNÍ POTVRZOVACÍ DIALOG ====================
const confirmModal = document.getElementById('confirm-modal');
const confirmText = document.getElementById('confirm-text');
const confirmYesBtn = document.getElementById('confirm-yes-btn');
const confirmNoBtn = document.getElementById('confirm-no-btn');
let confirmCallback = null;

function showConfirm(text, callback) {
    confirmText.textContent = text;
    confirmCallback = callback;
    confirmModal.classList.remove('hidden');
}

function hideConfirm() {
    confirmModal.classList.add('hidden');
    confirmCallback = null;
}

confirmYesBtn.addEventListener('click', () => {
    if (confirmCallback) {
        confirmCallback();
    }
    hideConfirm();
});

confirmNoBtn.addEventListener('click', hideConfirm);

// ==================== JOB MENU LOGIC ====================
const myJobsList = document.getElementById('my-jobs-list');
const currentJobLabel = document.getElementById('current-job-label');

function populateMyJobs(jobs, currentJob, currentJobLbl, currentGrade) {
    myJobsList.innerHTML = '';
    
    activeJobName = currentJob;
    currentJobLabel.textContent = `${currentJobLbl} (Hodnost: ${currentGrade})`;

    if (!jobs || jobs.length === 0) {
        myJobsList.innerHTML = '<p>Nemáte žádné další práce.</p>';
        return;
    }

    jobs.forEach(job => {
        const isActive = job.name === activeJobName;
        
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

    document.querySelectorAll('.set-active-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            post('setActiveJob', { jobName: e.target.dataset.jobName });
            closeNUI();
        });
    });

    document.querySelectorAll('.quit-job-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const buttonElement = e.target.closest('.quit-job-btn');
            const jobNameToQuit = buttonElement.dataset.jobName;

            if (jobNameToQuit) {
                // Použijeme náš vlastní dialog místo nativního confirm()
                showConfirm(`Opravdu chcete opustit práci ${jobNameToQuit}?`, () => {
                    post('quitJob', { jobName: jobNameToQuit });
                    closeNUI();
                });
            } else {
                console.error('[CHYBA] Nepodařilo se získat jobName z tlačítka!');
            }
        });
    });
}

// ==================== BOSS MENU LOGIC ====================
const employeesList = document.getElementById('employees-list');
let bossJobName = '';

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
        // Upravíme tlačítko pro propuštění, aby také používalo náš modal
        item.innerHTML = `
            <div class="item-info">
                <span>${emp.name}</span>
                <span>Hodnost: ${emp.grade}</span>
            </div>
            <div class="item-actions">
                <button class="promote-btn" data-charid="${emp.charid}" data-current-grade="${emp.grade}">Povýšit/Degradovat</button>
                <button class="fire-employee-btn fire-btn" data-charid="${emp.charid}" data-name="${emp.name}">Propustit</button>
            </div>
        `;
        employeesList.appendChild(item);
    });

    document.querySelectorAll('.promote-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const charid = e.target.dataset.charid;
            const currentGrade = e.target.dataset.currentGrade;
            // prompt() je také blokován, nahradíme ho v budoucnu, pokud bude třeba. Prozatím necháme.
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

    // Nový listener pro propouštění zaměstnanců
    document.querySelectorAll('.fire-employee-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const buttonElement = e.target.closest('.fire-employee-btn');
            const charid = buttonElement.dataset.charid;
            const name = buttonElement.dataset.name;

            showConfirm(`Opravdu chcete propustit zaměstnance ${name}?`, () => {
                post('fireEmployee', { 
                    charid: parseInt(charid),
                    jobName: bossJobName
                });
                closeNUI();
            });
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

    if (data.action === 'openMenu') {
        populateMyJobs(data.jobs, data.currentJob, data.currentJobLabel, data.currentGrade);

        const bossSection = document.getElementById('boss-section');
        if (data.isBoss) {
            document.getElementById('boss-panel-title').textContent = `Boss Panel (${data.currentJobLabel})`;
            populateEmployees(data.employees, data.currentJob);
            document.querySelector('.tab-button[data-tab="employees"]').click();
            bossSection.classList.remove('hidden');
        } else {
            bossSection.classList.add('hidden');
        }
        
        container.classList.remove('hidden');
    }
});


// ==================== DRAGGABLE WINDOW LOGIC ====================
const header = document.getElementById("main-header");
let isDragging = false;
let offsetX, offsetY;

header.addEventListener('mousedown', (e) => {
    if (e.target.tagName === 'BUTTON') return;
    isDragging = true;
    const rect = container.getBoundingClientRect();
    offsetX = e.clientX - rect.left;
    offsetY = e.clientY - rect.top;
    container.style.transform = 'none';
    container.style.left = `${rect.left}px`;
    container.style.top = `${rect.top}px`;
    header.style.cursor = 'grabbing';
});

document.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    container.style.left = `${e.clientX - offsetX}px`;
    container.style.top = `${e.clientY - offsetY}px`;
});

document.addEventListener('mouseup', () => {
    isDragging = false;
    header.style.cursor = 'grab';
});