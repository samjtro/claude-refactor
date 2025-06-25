# Build this project out to be a fully fledged program within claude code

### Helpful documentation

https://docs.anthropic.com/en/docs/claude-code/overview

### Overview

My vision for this claude setup is expansive; I'd like for it to operate as a wrapper for claude code within claude code.

I love the claude code environment, and the delegation of claude code to make small, granular changes within a scope. However, I find it lacking higher-level orchestration components I have to rewrite. I want to create a workflow script which encapsulates my entire project management lifecycle into a number of claude code + codex + any other tooling implementations running in parallel.

The new workflow I am envisioning takes inspiration from my project https://github.com/samjtro/claudebox , which uses a more streamlined version of the multi-agent setup in https://github.com/samjtro/claude-fsd , which itself is a downstream implementation of the original claude-fsd project. The multi-agent setup is then combined with the https://github.com/samjtro/agentic-project-management tools. 

Wherever you see fit, implement the APM & claude-fsd multi-agent prompts accordingly, combining them to create the ultimate multi-agent + hand-off development lifecycle system.

There are a few things I'd like to change: First, the APM & multi-agent setup are not properly integrated. I'd like to essentially combine the intelligence of the APM prompting & scripts with the automation & revolutionary multi-agent setup (with multiple instances) to create a singular suite for me. Secondly, the original claude-fsd was designed to be used as a whole-project buildout - the prompting reflects that. I want it to operate at the scope of a refactor - so any substantial codebase change, large or small, should be able to utilize the following structure:


### Workflow Structure


#### Instantiation

User initiates a refactor script by utilizing `/refactor <PATH_TO_GUIDE.md>`, which will pass the refactor guide the user created to the first claude code instance.

This refactor session should save all of its associated documents (QUESTIONS.md, PLAN.md, etc.) in a timestamped folder in the project for easy cleanup.

#### Step 1: Questions

**Claude Code Instance**

This instance is responsible for generating a set of questions, which are vitally important for the success of the project. These questions will be used to generate a comprehensive plan of action for this refactor, so the questions should be setup in the phases of the prospective refactor, which should then in turn be granular and comprehensive in scope, as to not miss anything of importance that the user may request.

```
Model: Opus

- [ ] Ultrathinks as an expert PM to examine the user's provided refactor guide and create a list of questions. The agent should go over the guide multiple times and iterate on the questions to fully understand the scope of what the user is attempting to accomplish from a high-level expert PM standpoint.
- [ ] The questions should be saved to a QUESTIONS.md file at the end of the session.
```

Then, the workflow script should prompt the user which editor they want to open the questions in (for now, just vim or nvim with nvim being the default), and open the file for them automatically.

Once the user has quit the session, the next claude code instance is instantiated with the questions document with the answers passed to it.

#### Step 2a: Plan

**Claude Code Instance**

This instance is responsible for generating a plan, synthesized from the user's provided guide and the user's answers to the previous agents questions. This plan should be split up into phases of TODO lists, but should also include comprehensive, granular guidance relating to again, the user's guide and the questions therein, as well as high-level instructions to keep the agents grounded in their tasks as to how it fits within the system being built.

```
Model: Opus

- [ ] Ultrathinks as an expert PM to examine the user's provided refactor guide, as well as the user's answers to the previous agents questions, and establish a plan. The agent should go over the guide & questions multiple times to fully understand the scope of what the user is attempting to accomplish from a high-level expert PM standpoint.
- [ ] The plan should then be saved to a PLAN.md file.
```

Copy the PLAN.md file to a new UPDATED_PLAN.md file.

This will now begin a loop, wherein the user will be prompted to edit the plan, with the same editor options as before (nvim as default + vim), which should then open the UPDATED_PLAN.md.

If the user HAS edited the UPDATED_PLAN.md file, `Step 2b` is instantiated with the updated plan passed to it, which then triggers the loop again.

If the user has NOT edited the UPDATED_PLAN.md file, break the loop and continue onto `Step 3`.

#### Step 2b: Updated plan loop

**Claude Code Instance**

```
Model: Opus

- [ ] Ultrathinks as an expert PM to examine the differences between the originally generated PLAN.md and the new UPDATED_PLAN.md. The agent should go over the guide multiple times to fully understand the scope of what the user is attempting to accomplish from a high-level expert PM standpoint, and generate a new PLAN.md with the user-requested updates.
- [ ] This new plan should then be saved to a PLAN.md file.
```

#### Step 3: Development lifecycle

Based on the phases established in the plan, we are going to setup a development lifecycle per phase.

##### Phase Lifecycle Architecture

This step involves multiple claude code instances spinning eachother up. Take your time to understand how to properly integrate this to mitigate some of the limitations of the traditional claude code setup.

**Claude Code Instances - Development**

```
Model: Opus, which then spins up Sonnet instances

- [ ] Ultrathinks as an expert PM to establish a complete set of tasks to be accomplished. The agent should go over the plan, guide & questions/answers multiple times to fully understand the scope of what the user is attempting to accomplish from a high-level expert PM standpoint. These tasks should be saved to a new TASKS_PHASE<PHASE_#>_<TIMESTAMP>.md file.
- [ ] For each task, spin up a single prompt Sonnet ultrathink session with a comprehensive plan to solve the task, once again based on all of the high-level and granular research done thus far to ground the model in the task.
- [ ] Then, once each task has been accomplished, have a new single prompt Sonnet ultrathink session establish a full-coverage test-suite for the refactor, and then have a final non-single prompt session run it in an interactive environment until it passes.

NOTE: Some of this will require additional scripting, do research within the confines of claude code to achieve the goals we want to achieve.
```

**Claude Code Instances - Reviewer**

```
Model: Opus

- [ ] Review all of the assigned tasks for the phase, how it compares to a the plan, guide & questions/answers multiple times to fully understand the scope of what the user is attempting to accomplish from a high-level expert PM standpoint. Then, review the test-suite and the implementation of the actual development lifecycle to ensure that everything is in line with what the user requested, and there are no loose ends / hallucinations / unfinished items.
```

If the phase passes review, the next phase of the development lifecycle should begin until every phase has been completed.

### Outcome

The goal of this is to take the disassembled, unorganized, frankly amateurish attempt at agentic project management and multi-agent development lifecycle management and turn it into a polished, comprehensive suite for fully end-to-end agentic project management lifecycles. Once you have finished incorporating, polishing, repolishing, etc. everything that exists, clean up the repository to make it easy to utilize the new structure in development while keeping the legacy items for reference later (but not as commands). This should be treated as an entirely sepearate task once done with the primary goal, as to not distract.
