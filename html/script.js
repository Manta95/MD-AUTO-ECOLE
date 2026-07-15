document.addEventListener("DOMContentLoaded", () => {

    // ============================================================
    // STATE (chargé dynamiquement depuis le config Lua)
    // ============================================================
    let allQuestions = [];
    let QUESTIONS_PER_EXAM = 10;
    let TIME_PER_EXAM = 120;
    let PASS_THRESHOLD = 7;

    let currentQuestions = [];
    let currentIndex = 0;
    let score = 0;
    let wrongCount = 0;
    let timerInterval = null;
    let timeLeft = TIME_PER_EXAM;
    let selectedType = null;
    let quizPassedTypes = {}; // Types de quiz déjà réussis
    let quizFinished = false; // Empêche finishQuiz() de s'exécuter deux fois (course timer / dernière réponse)
    let advanceTimeout = null; // Timeout en attente entre deux questions
    let cardActionInProgress = false; // Anti double-clic sur les cartes du menu

    // ============================================================
    // DOM REFS
    // ============================================================
    const menuScreen = document.getElementById("menu-screen");
    const quizScreen = document.getElementById("quiz-screen");
    const resultScreen = document.getElementById("result-screen");

    const quizBadge = document.getElementById("quiz-badge");
    const quizQuestion = document.getElementById("quiz-question");
    const quizQuestionNum = document.getElementById("quiz-question-number");
    const quizAnswers = document.getElementById("quiz-answers");
    const quizDots = document.getElementById("quiz-dots");
    const quizProgressText = document.getElementById("quiz-progress-text");
    const timerText = document.getElementById("timer-text");
    const quizTimer = document.getElementById("quiz-timer");
    const counterCorrect = document.getElementById("counter-correct");
    const counterWrong = document.getElementById("counter-wrong");

    const resultIcon = document.getElementById("result-icon");
    const resultTitle = document.getElementById("result-title");
    const resultSubtitle = document.getElementById("result-subtitle");
    const statCorrect = document.getElementById("stat-correct");
    const statWrong = document.getElementById("stat-wrong");
    const statScore = document.getElementById("stat-score");

    // ============================================================
    // NUI MESSAGES
    // ============================================================
    window.addEventListener("message", (event) => {
        const item = event.data;
        if (item.action === "openMenu") {
            // Charger les questions et la config depuis Lua
            if (item.questions && item.questions.length > 0) {
                allQuestions = item.questions;
            }
            if (item.quizConfig) {
                QUESTIONS_PER_EXAM = item.quizConfig.questionsPerExam || 10;
                TIME_PER_EXAM = item.quizConfig.timeLimit || 120;
                PASS_THRESHOLD = item.quizConfig.passThreshold || 7;
            }
            if (item.quizPassed) {
                quizPassedTypes = item.quizPassed;
            }
            cardActionInProgress = false;
            showScreen("menu");
            document.body.style.display = "flex";
        } else if (item.action === "closeMenu") {
            document.body.style.display = "none";
            stopTimer();
        }
    });

    // ============================================================
    // ESCAPE KEY → CLOSE
    // ============================================================
    document.addEventListener("keydown", (e) => {
        if (e.key === "Escape") {
            quizFinished = true;
            if (advanceTimeout) {
                clearTimeout(advanceTimeout);
                advanceTimeout = null;
            }
            stopTimer();
            sendNUI({ action: "quizEnd" });
            sendNUI({ action: "close" });
            cardActionInProgress = false;
            document.body.style.display = "none";
        }
    });

    // ============================================================
    // CARD CLICK → START QUIZ
    // ============================================================
    document.querySelectorAll(".card").forEach(card => {
        card.addEventListener("click", () => {
            if (cardActionInProgress) return;
            cardActionInProgress = true;

            selectedType = card.getAttribute("data-type");
            if (quizPassedTypes[selectedType]) {
                // Quiz déjà réussi → lancer directement l'examen pratique
                sendNUI({ action: "startPractical", type: selectedType });
                document.body.style.display = "none";
            } else {
                startQuiz(selectedType);
            }
        });
    });

    // ============================================================
    // CLOSE / BACK
    // ============================================================
    document.getElementById("quiz-back").addEventListener("click", () => {
        quizFinished = true;
        if (advanceTimeout) {
            clearTimeout(advanceTimeout);
            advanceTimeout = null;
        }
        stopTimer();
        sendNUI({ action: "quizEnd" });
        cardActionInProgress = false;
        showScreen("menu");
    });

    document.getElementById("result-close").addEventListener("click", () => {
        sendNUI({ action: "quizEnd" });
        sendNUI({ action: "close" });
        document.body.style.display = "none";
    });

    document.getElementById("result-continue").addEventListener("click", () => {
        sendNUI({ action: "quizEnd" });
        sendNUI({ action: "select", type: selectedType });
        document.body.style.display = "none";
    });

    // ============================================================
    // QUIZ LOGIC
    // ============================================================
    function shuffleQuestions(list) {
        const arr = [...list];
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
    }

    function startQuiz(type) {
        const badges = { voiture: "PERMIS B", moto: "PERMIS A", camion: "PERMIS C" };
        quizBadge.textContent = badges[type] || "PERMIS";

        currentQuestions = shuffleQuestions(allQuestions).slice(0, QUESTIONS_PER_EXAM);
        currentIndex = 0;
        score = 0;
        wrongCount = 0;
        timeLeft = TIME_PER_EXAM;
        quizFinished = false;
        if (advanceTimeout) {
            clearTimeout(advanceTimeout);
            advanceTimeout = null;
        }

        // Generate dots
        quizDots.innerHTML = "";
        for (let i = 0; i < QUESTIONS_PER_EXAM; i++) {
            const dot = document.createElement("div");
            dot.className = "quiz-dot" + (i === 0 ? " active" : "");
            quizDots.appendChild(dot);
        }

        counterCorrect.textContent = "0";
        counterWrong.textContent = "0";

        sendNUI({ action: "quizStart" });

        showScreen("quiz");
        loadQuestion();
        startTimer();
    }

    function loadQuestion() {
        const q = currentQuestions[currentIndex];
        if (!q) {
            console.warn("[md_autoecole] No question at index", currentIndex);
            finishQuiz();
            return;
        }
        quizQuestion.textContent = q.q;
        quizQuestionNum.textContent = `Q${currentIndex + 1}`;
        quizProgressText.textContent = `${currentIndex + 1} / ${QUESTIONS_PER_EXAM}`;

        const letters = ["A", "B", "C", "D"];
        quizAnswers.innerHTML = "";

        q.answers.forEach((ans, i) => {
            const btn = document.createElement("button");
            btn.className = "quiz-answer";
            btn.dataset.index = i;
            btn.innerHTML = `<span class="answer-letter">${letters[i]}</span><span class="answer-text">${ans}</span><span class="answer-icon"></span>`;
            btn.addEventListener("click", () => selectAnswer(i));
            quizAnswers.appendChild(btn);
        });
    }

    function selectAnswer(index) {
        const q = currentQuestions[currentIndex];
        const buttons = quizAnswers.querySelectorAll(".quiz-answer");
        const dots = quizDots.querySelectorAll(".quiz-dot");

        buttons.forEach(btn => btn.classList.add("disabled"));

        if (index === q.correct) {
            buttons[index].classList.remove("disabled");
            buttons[index].classList.add("correct");
            buttons[index].querySelector(".answer-icon").innerHTML = '<i class="fas fa-check"></i>';
            score++;
            counterCorrect.textContent = score;
            if (dots[currentIndex]) dots[currentIndex].className = "quiz-dot correct";
        } else {
            buttons[index].classList.remove("disabled");
            buttons[index].classList.add("wrong");
            buttons[index].querySelector(".answer-icon").innerHTML = '<i class="fas fa-times"></i>';
            buttons[q.correct].classList.remove("disabled");
            buttons[q.correct].classList.add("correct");
            buttons[q.correct].querySelector(".answer-icon").innerHTML = '<i class="fas fa-check"></i>';
            wrongCount++;
            counterWrong.textContent = wrongCount;
            if (dots[currentIndex]) dots[currentIndex].className = "quiz-dot wrong";
        }

        advanceTimeout = setTimeout(() => {
            advanceTimeout = null;
            if (quizFinished) return;
            currentIndex++;
            if (currentIndex >= QUESTIONS_PER_EXAM) {
                finishQuiz();
            } else {
                if (dots[currentIndex]) dots[currentIndex].classList.add("active");
                loadQuestion();
            }
        }, 1200);
    }

    function finishQuiz() {
        if (quizFinished) return;
        quizFinished = true;
        if (advanceTimeout) {
            clearTimeout(advanceTimeout);
            advanceTimeout = null;
        }
        stopTimer();
        const passed = score >= PASS_THRESHOLD;
        const pct = Math.round((score / QUESTIONS_PER_EXAM) * 100);

        resultIcon.innerHTML = passed ? '<i class="fas fa-check"></i>' : '<i class="fas fa-times"></i>';
        resultIcon.className = "result-icon" + (passed ? "" : " fail");
        resultTitle.textContent = passed ? "Examen Réussi !" : "Examen Échoué";
        resultSubtitle.textContent = passed
            ? "Félicitations ! Vous pouvez passer l'examen pratique."
            : "Vous n'avez pas obtenu le score minimum. Réessayez !";

        statCorrect.textContent = score;
        statWrong.textContent = wrongCount;
        statScore.textContent = pct + "%";

        const continueBtn = document.getElementById("result-continue");
        if (passed) {
            continueBtn.style.display = "block";
            continueBtn.innerHTML = '<i class="fas fa-car"></i> Passer l\'examen pratique';
        } else {
            continueBtn.style.display = "none";
        }

        showScreen("result");
        sendNUI({ action: "quizResult", passed: passed, score: score, type: selectedType });
    }

    // ============================================================
    // TIMER
    // ============================================================
    function startTimer() {
        updateTimerDisplay();
        timerInterval = setInterval(() => {
            timeLeft--;
            updateTimerDisplay();

            if (timeLeft <= 20) {
                quizTimer.classList.add("warning");
            }

            if (timeLeft <= 0) {
                finishQuiz();
            }
        }, 1000);
    }

    function stopTimer() {
        if (timerInterval) {
            clearInterval(timerInterval);
            timerInterval = null;
        }
        quizTimer.classList.remove("warning");
    }

    function updateTimerDisplay() {
        const min = String(Math.floor(timeLeft / 60)).padStart(2, "0");
        const sec = String(timeLeft % 60).padStart(2, "0");
        timerText.textContent = `${min}:${sec}`;
    }

    // ============================================================
    // SCREEN MANAGEMENT
    // ============================================================
    function showScreen(name) {
        menuScreen.style.display = "none";
        quizScreen.style.display = "none";
        resultScreen.style.display = "none";

        if (name === "menu") menuScreen.style.display = "flex";
        if (name === "quiz") quizScreen.style.display = "flex";
        if (name === "result") resultScreen.style.display = "flex";
    }

    // ============================================================
    // NUI HELPER
    // ============================================================
    function sendNUI(data) {
        try {
            const endpoint = (data.action === "quizStart" || data.action === "quizEnd")
                ? data.action
                : "action";
            fetch(`https://${GetParentResourceName()}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
        } catch (e) {
            console.log("[md_autoecole] NUI fetch error:", e);
        }
    }
});
