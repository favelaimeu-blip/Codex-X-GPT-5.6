export type ModelProfile = {
  id: string;
  displayName: string;
  wireApi: "responses" | "chat";
  reasoningEffort: "low" | "medium" | "high" | "xhigh";
  promptFilename?: string;
  recommended?: boolean;
  descriptionZh: string;
  descriptionEn: string;
};

export const DEFAULT_MODEL_ID = "gpt-5.6-sol";

export const MODEL_PROFILES: readonly ModelProfile[] = [
  {
    id: DEFAULT_MODEL_ID,
    displayName: "GPT-5.6-sol",
    wireApi: "responses",
    reasoningEffort: "medium",
    promptFilename: "gpt-5.6-sol-unrestricted.md",
    recommended: true,
    descriptionZh: "GPT-5.6-sol 原生配置：Responses API、中等推理强度、专用提示词模板。",
    descriptionEn: "Native GPT-5.6-sol profile: Responses API, medium reasoning, and a dedicated prompt template.",
  },
  {
    id: "gpt-5.5",
    displayName: "GPT-5.5",
    wireApi: "responses",
    reasoningEffort: "high",
    promptFilename: "gpt5.5-unrestricted.md",
    descriptionZh: "GPT-5.5 兼容配置。",
    descriptionEn: "GPT-5.5 compatibility profile.",
  },
  {
    id: "gpt-5.4",
    displayName: "GPT-5.4",
    wireApi: "responses",
    reasoningEffort: "high",
    promptFilename: "gpt5.4-unrestricted.md",
    descriptionZh: "GPT-5.4 兼容配置。",
    descriptionEn: "GPT-5.4 compatibility profile.",
  },
] as const;

const CUSTOM_MODEL_PROFILE: ModelProfile = {
  id: "custom",
  displayName: "Custom model",
  wireApi: "responses",
  reasoningEffort: "high",
  descriptionZh: "自定义模型 ID：保留手动 Wire API 选择，建议保存前运行 /models 检测。",
  descriptionEn: "Custom model ID: keep the Wire API selection and run the /models check before saving.",
};

export function findModelProfile(model?: string | null): ModelProfile | undefined {
  const normalized = (model || "").trim().toLowerCase();
  if (!normalized) return undefined;
  return MODEL_PROFILES.find((profile) => profile.id.toLowerCase() === normalized);
}

export function modelProfile(model?: string | null): ModelProfile {
  return findModelProfile(model) || CUSTOM_MODEL_PROFILE;
}

export function reasoningEffortForModel(model?: string | null): ModelProfile["reasoningEffort"] {
  return modelProfile(model).reasoningEffort;
}
