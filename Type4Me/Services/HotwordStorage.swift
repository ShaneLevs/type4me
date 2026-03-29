import Foundation

/// Stores and loads user-defined hotwords for ASR bias.
/// One word per line in UserDefaults.
enum HotwordStorage {

    private static let key = "tf_hotwords"
    private static let seededKey = "tf_hotwords_seeded"

    /// Example hotwords seeded on first launch.
    private static let exampleHotwords = ["claude", "claude code"]

    /// Seeds example hotwords on first launch. Call once from app startup.
    static func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        if load().isEmpty {
            save(exampleHotwords)
        }
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    static func load() -> [String] {
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        return raw.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func save(_ words: [String]) {
        UserDefaults.standard.set(words.joined(separator: "\n"), forKey: key)
    }

    static func loadRaw() -> String {
        UserDefaults.standard.string(forKey: key) ?? ""
    }

    static func saveRaw(_ text: String) {
        UserDefaults.standard.set(text, forKey: key)
    }

    // MARK: - Built-in hotwords

    /// Common tech terms that ASR engines frequently mis-transcribe.
    /// Covers AI models, dev tools, programming terms, frameworks, business jargon, and daily tech.
    static let builtinHotwords: [String] = [
        // ── AI models & companies ──
        "Claude", "Claude Code", "GPT", "GPT-4", "GPT-4o", "Gemini", "LLaMA", "Llama",
        "Anthropic", "OpenAI", "DeepSeek", "Qwen", "Mistral", "Cohere", "Perplexity",
        "Midjourney", "Stable Diffusion", "ComfyUI", "Hugging Face", "xAI", "Grok",
        "Copilot", "ChatGPT", "DALL-E", "Whisper", "Sora",

        // ── Dev tools ──
        "GitHub", "GitLab", "VS Code", "Cursor", "Docker", "Kubernetes",
        "Terraform", "Homebrew", "npm", "pip", "Vercel", "Netlify", "Supabase",
        "Firebase", "Redis", "PostgreSQL", "MongoDB", "Elasticsearch", "Grafana",
        "Prometheus", "Nginx", "Ollama", "Pinecone", "ChromaDB", "Weaviate",

        // ── Programming terms ──
        "API", "SDK", "LLM", "ASR", "token", "prompt", "fine-tune", "fine-tuning",
        "embedding", "RAG", "webhook", "microservice", "DevOps", "CI/CD", "GraphQL",
        "WebSocket", "REST", "OAuth", "JWT", "CORS", "SSL", "DNS", "CRUD",
        "refactor", "linting", "boilerplate", "serialization",

        // ── Frameworks & languages ──
        "React", "Next.js", "Vue", "Angular", "SwiftUI", "PyTorch", "TensorFlow",
        "LangChain", "Tailwind", "TypeScript", "JavaScript", "Rust", "Kotlin",
        "Flutter", "Django", "FastAPI", "Express", "Vite", "Nuxt", "SvelteKit",
        "Prisma", "Drizzle",

        // ── Business & work ──
        "deadline", "meeting", "schedule", "feedback", "stakeholder", "milestone",
        "roadmap", "KPI", "OKR", "standup", "sprint", "backlog", "retrospective",
        "onboarding", "sync", "blockers",

        // ── Daily high-freq tech ──
        "Wi-Fi", "Bluetooth", "AirDrop", "iCloud", "FaceTime", "App Store",
        "podcast", "playlist", "subscription", "screenshot", "notification",
        "AirPods", "HomePod", "MacBook", "iPad",
    ]

    /// Returns builtin + user hotwords merged (deduplicated, case-insensitive).
    static func loadEffective() -> [String] {
        let user = load()
        var seen = Set(builtinHotwords.map { $0.lowercased() })
        var result = builtinHotwords
        for word in user {
            let lower = word.lowercased()
            if !seen.contains(lower) {
                seen.insert(lower)
                result.append(word)
            }
        }
        return result
    }
}
