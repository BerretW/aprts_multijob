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
        if (!confirmModal.classList.contains('hidden')) {
            hideConfirm();
        } else if (!promptModal.classList.contains('hidden')) {
            hidePrompt();
        } else if (!hireModal.classList.contains('hidden')) { // <-- PŘIDÁNO
            hideHireModal();
        } else {
            closeNUI();
        }
    }
});

// ==================== VLASTNÍ MODÁLNÍ OKNA ====================

// --- CONFIRM (ANO/NE) ---
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
    if (confirmCallback) confirmCallback();
    hideConfirm();
});
confirmNoBtn.addEventListener('click', hideConfirm);

// --- PROMPT (ZADÁNÍ HODNOTY) ---
const promptModal = document.getElementById('prompt-modal');
const promptText = document.getElementById('prompt-text');
const promptInput = document.getElementById('prompt-input');
const promptSubmitBtn = document.getElementById('prompt-submit-btn');
const promptCancelBtn = document.getElementById('prompt-cancel-btn');
let promptCallback = null;

function showPrompt(text, placeholder, callback) {
    promptText.textContent = text;
    promptInput.value = '';
    promptInput.placeholder = placeholder || '';
    promptCallback = callback;
    promptModal.classList.remove('hidden');
    promptInput.focus();
}
function hidePrompt() {
    promptModal.classList.add('hidden');
    promptCallback = null;
}
promptSubmitBtn.addEventListener('click', () => {
    if (promptCallback) promptCallback(promptInput.value);
    hidePrompt();
});
promptCancelBtn.addEventListener('click', hidePrompt);
promptInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        promptSubmitBtn.click();
    }
});

// ==========================================================
// === NOVÁ SEKCE: HIRE (ZADÁNÍ ID HRÁČE) ===
// ==========================================================
const hireModal = document.getElementById('hire-modal');
const hireInput = document.getElementById('hire-input');
const hireSubmitBtn = document.getElementById('hire-submit-btn');
const hireCancelBtn = document.getElementById('hire-cancel-btn');
let hireCallback = null;

function showHireModal(callback) {
    hireInput.value = '';
    hireCallback = callback;
    hireModal.classList.remove('hidden');
    hireInput.focus();
}
function hideHireModal() {
    hireModal.classList.add('hidden');
    hireCallback = null;
}
hireSubmitBtn.addEventListener('click', () => {
    if (hireCallback) hireCallback(hireInput.value);
    hideHireModal();
});
hireCancelBtn.addEventListener('click', hideHireModal);
hireInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        hireSubmitBtn.click();
    }
});


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
            const jobNameToQuit = e.target.closest('.quit-job-btn').dataset.jobName;
            if (jobNameToQuit) {
                showConfirm(`Opravdu chcete opustit práci ${jobNameToQuit}?`, () => {
                    post('quitJob', { jobName: jobNameToQuit });
                    closeNUI();
                });
            }
        });
    });
}

// ==================== BOSS MENU LOGIC ====================
const employeesList = document.getElementById('employees-list');
let bossJobName = '';

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
                <button class="promote-btn" data-charid="${emp.charid}" data-current-grade="${emp.grade}" data-name="${emp.name}">Povýšit/Degradovat</button>
                <button class="fire-employee-btn fire-btn" data-charid="${emp.charid}" data-name="${emp.name}">Propustit</button>
            </div>
        `;
        employeesList.appendChild(item);
    });

    attachBossMenuListeners();
}

function attachBossMenuListeners() {
    document.querySelectorAll('.promote-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const button = e.target.closest('.promote-btn');
            const charid = button.dataset.charid;
            const currentGrade = button.dataset.currentGrade;
            const name = button.dataset.name;

            showPrompt(`Zadejte novou hodnost pro ${name}:`, currentGrade, (newGrade) => {
                if (newGrade !== null && newGrade !== '' && !isNaN(newGrade) && newGrade >= 0) {
                    post('setGrade', { 
                        charid: parseInt(charid), 
                        newGrade: parseInt(newGrade),
                        jobName: bossJobName 
                    });
                    closeNUI();
                } else if (newGrade !== null && newGrade !== '') {
                    console.log('Zadána neplatná hodnota pro grade.');
                }
            });
        });
    });

    document.querySelectorAll('.fire-employee-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const button = e.target.closest('.fire-employee-btn');
            const charid = button.dataset.charid;
            const name = button.dataset.name;

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

// ZMĚNA ZDE: Tlačítko nyní volá naši novou funkci showHireModal
document.getElementById('hire-player-btn').addEventListener('click', () => {
    if (!bossJobName) {
        console.error("Chyba: Není definována práce pro nábor!");
        return;
    }
    // Voláme nové, dedikované modální okno
    showHireModal((playerId) => {
        const id = parseInt(playerId);
        if (id && id > 0) {
            post('hirePlayerById', { 
                targetId: id,
                jobName: bossJobName
            });
            closeNUI();
        } else if (playerId !== null && playerId !== '') {
            console.log("Zadáno neplatné ID hráče.");
        }
    });
});

// ==================== MAIN EVENT LISTENER & DRAG LOGIC ====================
// ... (tato část zůstává beze změny) ...
window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'openMenu') {
        populateMyJobs(data.jobs, data.currentJob, data.currentJobLabel, data.currentGrade);
        const bossSection = document.getElementById('boss-section');
        const tabButtons = document.querySelectorAll('.tab-button');

        tabButtons.forEach(button => {
            button.addEventListener('click', () => {
                tabButtons.forEach(btn => btn.classList.remove('active'));
                button.classList.add('active');
                
                document.querySelectorAll('.tab-content').forEach(content => {
                    content.classList.add('hidden');
                });
                document.getElementById(button.dataset.tab + '-tab').classList.remove('hidden');
            });
        });

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