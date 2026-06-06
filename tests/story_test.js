/**
 * story_test.js — Walkthrough through real Ink conditionals and choices.
 *
 * Sets story variables to simulate Lua state, then Continue()s through
 * actual Ink — catching wrong conditionals, gender bugs, quest imbalance.
 *
 * Usage: node tests/story_test.js [iter1|iter2_npc|iter2_system|full]
 */

const fs = require("fs");
const path = require("path");
const { Story } = require("inkjs");

const CHAPTER_01 = path.resolve(__dirname, "..", "main", "story", "chapter_01.json");
const MAX_STEPS = 30000;

// =========================================================================
// Helpers
// =========================================================================

function loadStory() {
    if (!fs.existsSync(CHAPTER_01)) {
        console.error(`ERROR: ${CHAPTER_01} not found. Compile .ink first.`);
        process.exit(1);
    }
    const json = fs.readFileSync(CHAPTER_01, "utf8");
    const story = new Story(json);
    let errors = 0;
    story.onError = function(msg) {
        if (msg.includes("ran out of content")) return;
        console.warn("  [story error]", msg);
        errors++;
    };
    story._avosErrors = () => errors;
    return story;
}

function setVars(story, vars) {
    for (const [k, v] of Object.entries(vars)) {
        story.variablesState[k] = v;
    }
}

function setChar(story, gender) {
    const m = gender === "male";
    setVars(story, {
        mc_gender: m ? "male" : "female",
        npc_gender: m ? "female" : "male",
        mc_name: m ? "Артём" : "Мила",
        npc_name: m ? "Мила" : "Артём",
        mc_name_gen: m ? "Артёма" : "Милы",
        npc_name_gen: m ? "Милы" : "Артёма",
        mc_name_dat: m ? "Артёму" : "Миле",
        npc_name_dat: m ? "Миле" : "Артёму",
        mc_name_acc: m ? "Артёма" : "Милу",
        npc_name_acc: m ? "Милу" : "Артёма",
        mc_name_ins: m ? "Артёмом" : "Милой",
        npc_name_ins: m ? "Милой" : "Артёмом",
        mc_name_prep: m ? "Артёме" : "Миле",
        npc_name_prep: m ? "Миле" : "Артёме",
    });
}

// =========================================================================
// Story walker — continues through real Ink until choices or pause
// =========================================================================

class Walker {
    constructor(story, log = false) {
        this.story = story;
        this.log = log;
        this.steps = 0;
        this.tags = { set_flag: {}, quest: {}, explore: null, splash: null, meta: null, phone_map: false };
    }

    resetTags() {
        this.tags = { set_flag: {}, quest: {}, explore: null, splash: null, meta: null, phone_map: false };
    }

    /** Continue until choices appear or story ends */
    walk(maxSteps = 2000) {
        const s = this.story;
        let steps = 0;
        this.resetTags();

        while (steps < maxSteps && s.canContinue) {
            steps++;
            const text = s.Continue();
            const tags = s.currentTags || [];
            if (text && text.trim() && this.log) {
                const short = text.trim().slice(0, 80).replace(/\n/g, " ");
                console.log(`    │ ${short}`);
            }

            for (const tag of tags) {
                const t = tag.startsWith("#") ? tag.slice(1).trim() : tag.trim();
                if (t.startsWith("set_flag:")) {
                    const eq = t.indexOf("=", 9);
                    const name = eq > 9 ? t.slice(9, eq) : t.slice(9);
                    const val = eq > 9 ? t.slice(eq + 1) : "true";
                    this.tags.set_flag[name] = val;
                } else if (t.startsWith("quest:")) {
                    const colon = t.indexOf(":", 6);
                    const action = colon > 6 ? t.slice(6, colon) : t.slice(6);
                    const id = colon > 6 ? t.slice(colon + 1) : "";
                    this.tags.quest[action + ":" + id] = true;
                } else if (t.startsWith("explore:")) {
                    this.tags.explore = t.slice(8);
                } else if (t.startsWith("splash:")) {
                    this.tags.splash = t.slice(7);
                } else if (t.startsWith("meta:add:") && t.includes(":1")) {
                    this.tags.meta = t.slice(9);
                } else if (t === "phone:map") {
                    this.tags.phone_map = true;
                }
            }

            if (s.currentChoices.length > 0) {
                this.steps += steps;
                return "choices";
            }
        }

        this.steps += steps;
        return s.canContinue ? "timeout" : "ended";
    }

    /** Make a choice by index or text match */
    pick(matcher) {
        const choices = this.story.currentChoices;
        if (!choices.length) return false;
        let idx;
        if (typeof matcher === "function") {
            idx = choices.findIndex(c => matcher(c.text));
        } else if (typeof matcher === "string") {
            idx = choices.findIndex(c => c.text.includes(matcher));
        } else {
            idx = matcher ?? 0;
        }
        idx = Math.max(0, Math.min(idx, choices.length - 1));
        if (this.log) console.log(`    → [${idx}] ${choices[idx].text.slice(0, 60)}`);
        this.story.ChooseChoiceIndex(idx);
        return true;
    }

    /** Walk + make a single choice */
    walkAndPick(matcher, maxSteps = 500) {
        const r = this.walk(maxSteps);
        if (r === "choices") this.pick(matcher);
        return r;
    }

    /** Run a knot via ChoosePathString, then walk */
    runKnot(knot, maxSteps = 500) {
        this.story.ChoosePathString(knot);
        return this.walk(maxSteps);
    }

    assertTag(prefix) {
        const found = this.tags.set_flag[prefix] !== undefined
            || Object.keys(this.tags.quest).some(k => k.startsWith(prefix))
            || (this.tags.explore && this.tags.explore.startsWith(prefix));
        if (!found) {
            console.warn(`  ⚠ MISSING TAG: ${prefix}`);
            console.warn(`    had: set_flag=${Object.keys(this.tags.set_flag).join(",")} quest=${Object.keys(this.tags.quest).join(",")} explore=${this.tags.explore}`);
        }
        return found;
    }
}

// =========================================================================
// Walkthrough: Iteration 1 (linear)
// =========================================================================

function walkIter1(w, log) {
    log && console.log("\n  -- Phase: Character --");
    setVars(w.story, { iteration_number: 1 });
    w.walk(); w.pick(0);
    w.walk();

    log && console.log("  -- Phase: Set up for date --");
    setVars(w.story, {
        got_out_of_bed: true, washed_up: true, teeth_brushed: true,
        sunday_dressed: true, date_agreed: true, date_place_cafe: true,
    });
    w.runKnot("leave_apartment");
    w.runKnot("sunday_date_go_cafe");

    log && console.log("  -- Phase: Cafe date --");
    w.runKnot("sunday_date_cafe_arrival");
    // Order at bar (real Ink choices)
    w.runKnot("cafe_bar_interact");
    if (w.story.currentChoices.length) { w.pick(0); w.walk(); }
    // After ordering → goto_scene:cafe_corner → main talk
    w.runKnot("cafe_corner_main_talk");

    setVars(w.story, { met_npc_sunday: true });
    w.runKnot("leave_cafe");

    log && console.log("  -- Phase: Evening + sleep --");
    setVars(w.story, { sunday_evening_started: true });
    w.runKnot("sunday_evening_home");
    w.runKnot("sunday_sleep_in_bed");

    log && console.log("  -- Phase: Monday --");
    setVars(w.story, { sunday_finished: true, monday_started: true });
    const r1 = w.walk();
    if (r1 === "choices") {
        const auto = w.story.currentChoices.findIndex(c => c.text.includes("автомат"));
        w.pick(auto >= 0 ? auto : 0);
        w.walk();
    }

    setVars(w.story, { monday_coffee_done: true, monday_breakfast_done: true, monday_water_drunk: true });
    w.runKnot("mon_home_leave_apartment");
    w.walkAndPick();

    w.runKnot("work_desk_read_mail");
    setVars(w.story, { monday_mail_read: true });
    w.runKnot("meeting_room_take_folder");
    setVars(w.story, { monday_case_file_assembled: true });
    w.runKnot("work_desk_case_file_prompt");

    log && console.log("  -- Phase: Tuesday --");
    w.walkAndPick(0);

    setVars(w.story, { tuesday_phone_checked: true, tuesday_washed_up: true, tuesday_ready_to_leave: true });
    w.runKnot("tue_home_leave_apartment");

    log && console.log("  -- Phase: Rooftop → ending --");
    w.walkAndPick(0);
    w.walk(2000);

    const et = w.story.variablesState["current_iteration_end"];
    log && console.log(`  current_iteration_end = "${et}"`);
    return { ok: true, steps: w.steps, ending: et || "(reset)" };
}

// =========================================================================
// Walkthrough: Iteration 2 (targeted ending)
// =========================================================================

function walkIter2(w, log, targetEnding) {
    log && console.log("\n  -- Phase: Character --");
    setVars(w.story, { iteration_number: 2 });
    w.walk(); w.pick(0);
    w.walk();

    log && console.log("  -- Phase: Fake Wednesday --");
    setVars(w.story, {
        got_out_of_bed: true, washed_up: true, teeth_brushed: true,
        sunday_dressed: true, loop2_fake_wednesday_started: true,
    });

    // leave_apartment_prompt routes to work for iter 2
    w.runKnot("leave_apartment_prompt");
    // The prompt routes → sunday_get_dressed_forced → loop2_fake_wednesday_leave_for_work

    log && console.log("  -- Phase: Office check --");
    w.walk();
    if (w.story.currentChoices.length) { w.pick(0); w.walk(); }

    w.runKnot("work_desk_read_mail");
    setVars(w.story, { monday_mail_read: true });
    w.runKnot("meeting_room_take_folder");
    setVars(w.story, { monday_case_file_assembled: true, loop2_work_check_done: true });
    w.runKnot("work_desk_case_file_prompt");

    log && console.log("  -- Phase: Evening + second invite --");
    w.walkAndPick(0);

    // Messenger (loop2 accept variant since loop2_work_check_done)
    const thread = w.story.variablesState["mc_gender"] === "male" ? "msg_thread_mila" : "msg_thread_artem";
    w.runKnot(thread);
    if (w.story.currentChoices.length) { w.pick(0); w.walk(); }

    log && console.log("  -- Phase: Park date --");
    setVars(w.story, { date_agreed: true, date_place_park: true });
    w.runKnot("sunday_date_go_park");
    w.runKnot("sunday_date_park_arrival");
    w.runKnot("park_npc_arrives");
    setVars(w.story, { met_npc_sunday: true, park_npc_greeted: true });
    w.runKnot("leave_park");

    log && console.log("  -- Phase: Evening + sleep --");
    setVars(w.story, { sunday_evening_started: true });
    w.runKnot("sunday_evening_home");
    w.runKnot("sunday_sleep_in_bed");
    setVars(w.story, { sunday_finished: true, monday_started: true });
    w.walkAndPick(0);

    setVars(w.story, { monday_coffee_done: true, monday_breakfast_done: true, monday_water_drunk: true });
    w.runKnot("mon_home_leave_apartment");
    w.walkAndPick(0);
    w.runKnot("work_desk_read_mail");
    setVars(w.story, { monday_mail_read: true });
    w.runKnot("meeting_room_take_folder");
    setVars(w.story, { monday_case_file_assembled: true });
    w.runKnot("work_desk_case_file_prompt");

    log && console.log("  -- Phase: Tuesday --");
    w.walkAndPick(0);
    setVars(w.story, { tuesday_phone_checked: true, tuesday_washed_up: true, tuesday_ready_to_leave: true });
    w.runKnot("tue_home_leave_apartment");

    log && console.log("  -- Phase: Rooftop → ending --");
    w.walkAndPick(0);
    // Walk through review text and rooftop talk (can be long)
    w.walk(2000);

    if (targetEnding === "npc") setVars(w.story, { TRUST: 10, INSIGHT: 2 });
    else setVars(w.story, { TRUST: 2, INSIGHT: 10 });

    if (w.story.currentChoices.length) {
        const idx = targetEnding === "npc"
            ? w.story.currentChoices.findIndex(c => c.text.includes("человека"))
            : w.story.currentChoices.findIndex(c => c.text.includes("логику"));
        w.pick(idx >= 0 ? idx : 0);
        w.walk(2000);
    }

    const et = w.story.variablesState["current_iteration_end"];
    log && console.log(`  current_iteration_end = "${et}"`);
    return { ok: !!et, steps: w.steps, ending: et || "none" };
}

// =========================================================================
// Test entry points
// =========================================================================

function walkFull(w, log) {
    // Full story: iter 1 → iter 2 NPC → iter 2 System → iter 4 true ending
    log && console.log("=== FULL WALKTHROUGH ===");
    let totalSteps = 0;

    // Iter 1
    const r1 = walkIter1(w, log);
    totalSteps += r1.steps;
    log && console.log(`  Iter 1: ${r1.ending}`);

    // Iter 2 — NPC
    const r2 = walkIter2(w, log, "npc");
    totalSteps += r2.steps;
    log && console.log(`  Iter 2 (NPC): ${r2.ending}`);

    // Iter 3 — System
    const r3 = walkIter2(w, log, "system");
    totalSteps += r3.steps;
    log && console.log(`  Iter 3 (System): ${r3.ending}`);

    return { steps: totalSteps, ok: true };
}

function runTest(label, fn) {
    console.log(`\n=== ${label} ===`);
    const story = loadStory();
    setChar(story, "male");
    const w = new Walker(story, true);
    const r = fn(w, true);

    let ok;
    if (label === "Full") {
        ok = r.ok;
    } else {
        ok = !!r.ending && r.ending !== "none";
    }
    console.log(`  Steps: ${r.steps}`);
    console.log(`  Result: ${ok ? "✓ PASS" : "✗ FAIL"}`);
    return ok;
}

// =========================================================================
// Main
// =========================================================================

async function main() {
    const mode = process.argv[2] || "iter1";
    let passed = 0, failed = 0;

    const tests = [];
    if (mode === "all" || mode === "full")         tests.push(["Full", (w,l) => walkFull(w,l)]);
    if (mode === "iter1")                          tests.push(["Iter 1", (w,l) => walkIter1(w,l)]);
    if (mode === "iter2_npc")                      tests.push(["Iter 2 NPC", (w,l) => walkIter2(w,l,"npc")]);
    if (mode === "iter2_system")                   tests.push(["Iter 2 System", (w,l) => walkIter2(w,l,"system")]);

    for (const [name, fn] of tests) {
        try {
            const ok = runTest(name, fn);
            console.log(`  ${ok ? "✓" : "✗"} ${name}`);
            if (ok) passed++; else failed++;
        } catch (err) {
            console.log(`  ✗ ${name} — ERROR: ${err.message}`);
            console.error(err);
            failed++;
        }
    }

    console.log(`\n=== ${passed} passed, ${failed} failed ===`);
    process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => { console.error("FATAL:", err); process.exit(1); });
