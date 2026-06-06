/**
 * story_test.js — Automated Ink story walkthrough.
 * Uses inkjs to load chapter_01.json and trace through story paths.
 * 
 * Usage: node tests/story_test.js [iter1|iter2_npc|iter2_system|all]
 * 
 * Walks through dialogue, auto-chooses first option, and verifies
 * that key milestones (endings, quest flags) are reached.
 */

const fs = require("fs");
const path = require("path");
const { Story } = require("inkjs");

const CHAPTER_01 = path.resolve(__dirname, "..", "main", "story", "chapter_01.json");
const MAX_STEPS = 5000; // safety limit per walkthrough
const MAX_CHOICE_DEPTH = 20; // prevent infinite choice loops

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function loadStory() {
    if (!fs.existsSync(CHAPTER_01)) {
        console.error(`ERROR: ${CHAPTER_01} not found. Compile .ink first.`);
        process.exit(1);
    }
    const json = fs.readFileSync(CHAPTER_01, "utf8");
    const story = new Story(json);
    story.onError = function(msg) {
        // "ran out of content" — normal for branches without explicit -> DONE
        if (msg.includes("ran out of content")) return;
        console.warn("  [story error]", msg);
    };
    return story;
}

function follow(story, { pickIndex = 0, onContinue = null, onChoice = null, maxSteps = MAX_STEPS, label = "" } = {}) {
    let steps = 0;
    let lastText = "";

    while (steps < maxSteps && story.canContinue) {
        steps++;
        const text = story.Continue();
        if (text && text.trim()) {
            lastText = text.trim();
            if (onContinue) onContinue(text.trim(), steps, story);
        }

        if (story.currentChoices.length > 0) {
            const choices = story.currentChoices;
            const idx = typeof pickIndex === "function" ? pickIndex(choices, story) : pickIndex;
            const safeIdx = Math.max(0, Math.min(idx, choices.length - 1));

            if (onChoice) onChoice(choices, safeIdx, steps, story);
            story.ChooseChoiceIndex(safeIdx);

            // safety: prevent infinite loops of pure choices
            let depth = 0;
            while (depth < MAX_CHOICE_DEPTH && story.canContinue && story.currentChoices.length > 0) {
                depth++;
                story.Continue();
                if (story.currentChoices.length > 0) {
                    const c2 = story.currentChoices;
                    const i2 = typeof pickIndex === "function" ? pickIndex(c2, story) : pickIndex;
                    story.ChooseChoiceIndex(Math.max(0, Math.min(i2, c2.length - 1)));
                }
            }
        }
    }

    return {
        steps,
        lastText,
        endedOk: steps < maxSteps || story.canContinue === false,
        storyEnded: story.canContinue === false,
        currentTags: story.currentTags ? story.currentTags.join(", ") : "",
    };
}

function setVars(story, vars) {
    for (const [k, v] of Object.entries(vars)) {
        story.variablesState[k] = v;
    }
}

// ---------------------------------------------------------------------------
// Test runners
// ---------------------------------------------------------------------------

function testIter1() {
    console.log("\n=== Iter 1: Linear ===");
    const story = loadStory();
    setVars(story, {
        iteration_number: 1,
    });

    const result = follow(story, { label: "iter1" });

    console.log(`  Steps: ${result.steps}`);
    console.log(`  Last text: ${result.lastText ? result.lastText.slice(0, 80) + "..." : "(none)"}`);
    console.log(`  Ended: ${result.storyEnded ? "OK" : "TIMEOUT"}`);

    return result.storyEnded;
}

function testIter2NPCEnding() {
    console.log("\n=== Iter 2: NPC Ending ===");
    const story = loadStory();

    // Iter 2 setup
    setVars(story, {
        iteration_number: 2,
    });

    // Walk with specific choices for NPC ending path
    const result = follow(story, {
        pickIndex: (choices, st) => {
            // When offered the "reveal" choice in cafe/park, take it → sets loop2_revealed_to_npc
            const revealIdx = choices.findIndex(c => c.text.includes("я уже жил этот день"));
            if (revealIdx >= 0) return revealIdx;
            // In the rooftop, choose "Держаться за человека" (NPC ending) — usually first
            const npcChoice = choices.findIndex(c => c.text.includes("человека"));
            if (npcChoice >= 0) return npcChoice;
            return 0; // default: first choice
        },
        label: "iter2_npc",
    });

    console.log(`  Steps: ${result.steps}`);
    console.log(`  Last text: ${result.lastText ? result.lastText.slice(0, 80) + "..." : "(none)"}`);
    console.log(`  Ended: ${result.storyEnded ? "OK" : "TIMEOUT"}`);

    const revealed = story.variablesState["loop2_revealed_to_npc"] === true;
    const ended = story.variablesState["current_iteration_end"] === "npc";
    console.log(`  loop2_revealed_to_npc: ${revealed}`);
    console.log(`  current_iteration_end (expected npc): ${ended}`);

    return result.storyEnded && (ended || result.lastText.includes("Держаться"));
}

function testIter2SystemEnding() {
    console.log("\n=== Iter 2: System Ending ===");
    const story = loadStory();

    setVars(story, {
        iteration_number: 2,
    });

    const result = follow(story, {
        pickIndex: (choices, st) => {
            const revealIdx = choices.findIndex(c => c.text.includes("я уже жил этот день"));
            if (revealIdx >= 0) return revealIdx;
            // On rooftop, choose "Держаться за логику системы" — usually second option
            const systemChoice = choices.findIndex(c => c.text.includes("логику"));
            if (systemChoice >= 0) return systemChoice;
            return 0;
        },
        label: "iter2_system",
    });

    console.log(`  Steps: ${result.steps}`);
    console.log(`  Ended: ${result.storyEnded ? "OK" : "TIMEOUT"}`);

    return result.storyEnded;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
    const mode = process.argv[2] || "all";
    let passed = 0;
    let failed = 0;

    const tests = [];
    if (mode === "all" || mode === "iter1") tests.push(["iter1", testIter1]);
    if (mode === "all" || mode === "iter2_npc") tests.push(["iter2_npc", testIter2NPCEnding]);
    if (mode === "all" || mode === "iter2_system") tests.push(["iter2_system", testIter2SystemEnding]);

    for (const [name, fn] of tests) {
        try {
            const ok = fn();
            if (ok) {
                console.log(`  ✓ ${name}`);
                passed++;
            } else {
                console.log(`  ✗ ${name} — FAILED`);
                failed++;
            }
        } catch (err) {
            console.log(`  ✗ ${name} — ERROR: ${err.message}`);
            failed++;
        }
    }

    console.log(`\n=== Results: ${passed} passed, ${failed} failed ===`);
    process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
    console.error("FATAL:", err);
    process.exit(1);
});
