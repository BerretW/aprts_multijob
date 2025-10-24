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

// Globální proměnná pro uchování jména aktivní práce
let activeJobName = '';

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
        closeNUI();
    }
});


// ==================== JOB MENU LOGIC ====================
const myJobsList = document.getElementById('my-jobs-list');
const currentJobLabel = document.getElementById('current-job-label');

function populateMyJobs(jobs, currentJob, currentJobLbl, currentGrade) {
    myJobsList.innerHTML = '';
    
    // Vždy použijeme čerstvá data z Lua
    activeJobName = currentJob;
    currentJobLabel.textContent = `${currentJobLbl} (Hodnost: ${currentGrade})`;

    if (!jobs || jobs.length === 0) {
        myJobsList.innerHTML = '<p>Nemáte žádné další práce.</p>';
        return;
    }

    jobs.forEach(job => {
        // Porovnáváme interní jméno práce (např. 'police') s aktivním jménem
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
            // OPRAVA ZDE: Zavoláme closeNUI() po odeslání požadavku
            closeNUI();
        });
    });

    document.querySelectorAll('.quit-job-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            if (confirm(`Opravdu chcete opustit práci ${e.target.dataset.jobName}?`)) {
                post('quitJob', { jobName: e.target.dataset.jobName });
                // OPRAVA ZDE: Zavoláme closeNUI() po potvrzení a odeslání požadavku
                closeNUI();
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
                // OPRAVA ZDE: Zavřeme okno po akci
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
                 // OPRAVA ZDE: Zavřeme okno po akci
                closeNUI();
            }
        });
    });
}

document.getElementById('hire-player-btn').addEventListener('click', () => {
    post('hirePlayer', { jobName: bossJobName });
    // U najmutí se okno zavírá už na straně Lua (v nui_handler.lua),
    // ale pro jistotu to můžeme přidat i sem.
    closeNUI();
});


// ==================== MAIN EVENT LISTENER ====================
// ... (beze změny)
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openMenu') {
        // Vždy naplníme základní info pomocí čerstvých dat ze statebagu
        populateMyJobs(data.jobs, data.currentJob, data.currentJobLabel, data.currentGrade);

        const bossSection = document.getElementById('boss-section');
        if (data.isBoss) {
            // Pokud je hráč šéf, zobrazíme a naplníme boss sekci
            document.getElementById('boss-panel-title').textContent = `Boss Panel (${data.currentJobLabel})`;
            populateEmployees(data.employees, data.currentJob); // Použijeme currentJob pro konzistenci
            // Reset na defaultní tab
            document.querySelector('.tab-button[data-tab="employees"]').click();
            bossSection.classList.remove('hidden');
        } else {
            // Jinak sekci skryjeme
            bossSection.classList.add('hidden');
        }
        
        container.classList.remove('hidden');
    }
});


// ==================== DRAGGABLE WINDOW LOGIC ====================
// ... (beze změny)
const header = document.getElementById("main-header");
let isDragging = false;
let offsetX, offsetY;

header.addEventListener('mousedown', (e) => {
    if (e.target.tagName === 'BUTTON') return;
    isDragging = true;
    offsetX = e.clientX - container.offsetLeft;
    offsetY = e.clientY - container.offsetTop;
    header.style.cursor = 'grabbing';
});

document.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    container.style.left = `${e.clientX - offsetX}px`;
    container.style.top = `${e.clientY - offsetY}px`;
    container.style.transform = 'translate(0, 0)';
});

document.addEventListener('mouseup', () => {
    isDragging = false;
    header.style.cursor = 'grab';
});