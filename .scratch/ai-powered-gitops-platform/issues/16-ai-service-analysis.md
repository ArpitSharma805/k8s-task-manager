# 16: AI Ops Service - Analysis and Teams Integration

**Status:** 🟡 READY TO START

**Objective:** Extend the AI Ops service to analyze evidence using Ollama, generate insights, and send notifications to Microsoft Teams via Adaptive Cards.

**Scope:**
- Integrate Ollama API for analysis
- Implement analysis logic for evidence
- Generate insights and recommendations
- Create Microsoft Teams Adaptive Cards
- Implement Teams webhook integration
- Add analysis API endpoints
- Document analysis workflow

**Acceptance Criteria:**
- [ ] AI Ops service integrates with Ollama
- [ ] Service analyzes evidence using Llama 3.1
- [ ] Service generates insights
- [ ] Service creates Teams Adaptive Cards
- [ ] Service sends notifications to Teams
- [ ] Analysis API endpoints work
- [ ] Teams notifications are received
- [ ] Analysis workflow is documented

**Dependencies:**
- 14 (Ollama Foundation) - Ollama must be running
- 15 (AI Service Evidence) - Evidence collection must work

**Deliverables:**
- `platform-core/ai-ops-service/app/analysis/ollama.py` - Ollama integration
- `platform-core/ai-ops-service/app/analysis/insights.py` - Insight generation
- `platform-core/ai-ops-service/app/notifications/teams.py` - Teams integration
- `platform-core/ai-ops-service/app/models/adaptive-card.py` - Adaptive Card models
- `platform-core/config/ai-ops/prompts/*.txt` - Analysis prompts
- `platform-core/docs/ai-ops/analysis.md` - Analysis documentation
- `platform-core/docs/ai-ops/teams-integration.md` - Teams integration guide

**Implementation Details:**

**Ollama Integration:**
- Connect to Ollama API
- Send evidence as context
- Use Llama 3.1 for analysis
- Parse model responses

**Analysis Prompts:**
- Build failure analysis
- Deployment failure analysis
- Performance issue analysis
- Security vulnerability analysis

**Adaptive Cards:**
- Title: AI Ops Insight
- Body: Evidence summary, analysis, recommendations
- Actions: View details, acknowledge, dismiss
- Styling: Color-coded by severity

**Teams Integration:**
- Webhook URL for Teams channel
- POST Adaptive Card to webhook
- Handle webhook responses
- Retry on failure

**API Endpoints:**
- POST /api/analyze - Trigger analysis
- POST /api/notify - Send Teams notification
- POST /api/analyze-and-notify - Combined operation

**Validation Steps:**
1. Implement Ollama integration
2. Test analysis with sample evidence
3. Verify insights are generated
4. Create Adaptive Card templates
5. Set up Teams webhook
6. Test Teams notification
7. Test combined analyze-and-notify endpoint
8. Deploy updated service
9. Trigger analysis from real evidence
10. Verify Teams notification received

**Definition of Done:**
- AI Ops service analyzes evidence
- Insights are generated using Llama 3.1
- Teams notifications are sent
- Adaptive Cards are formatted correctly
- Analysis workflow is documented
- Developer can trigger analysis and notifications
