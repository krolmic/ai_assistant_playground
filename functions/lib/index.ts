import { openAI } from '@genkit-ai/compat-oai/openai';
import { xAI } from '@genkit-ai/compat-oai/xai';
import { googleAI } from '@genkit-ai/googleai';
import { config } from 'dotenv';
import { setGlobalOptions } from "firebase-functions";
import { onCallGenkit } from 'firebase-functions/https';
import { defineSecret } from "firebase-functions/params";
import { promises as fs } from "fs";
import { unlink } from "fs/promises";
import { genkit, GenkitBeta, SessionData, SessionStore, z } from "genkit/beta";

if (process.env.FUNCTIONS_EMULATOR) {
  config({ path: '.secret.local' });
}

setGlobalOptions({ maxInstances: 10 });

const ai = genkit({
  plugins: [
    googleAI(),
    openAI({
      apiKey: process.env.OPENAI_API_KEY,
    }),
    xAI({
      apiKey: process.env.XAI_API_KEY,
    }),
  ],
});

type ModelType = "gemini" | "gpt" | "grok";
const modelMap: Record<ModelType, any> = {
  gemini: googleAI.model("gemini-2.5-flash", {
    temperature: 0.8,
  }),
  gpt: openAI.model("gpt-4o"),
  grok: xAI.model("grok-3-mini"),
};

type ImageModelType = "dallE";
const imageModelMap: Record<ImageModelType, any> = {
  dallE: openAI.model("dall-e-3"),
};

class JsonSessionStore<S = any> implements SessionStore<S> {
  async get(sessionId: string): Promise<SessionData<S> | undefined> {
    try {
      const s = await fs.readFile(`sessions/${sessionId}.json`, "utf8");
      const sessionData = JSON.parse(s);

      // Filter out messages with empty content arrays to prevent API errors
      if (sessionData.threads && sessionData.threads.main) {
        sessionData.threads.main = sessionData.threads.main.filter((message: any) => {
          return message.content && message.content.length > 0;
        });
      }

      return sessionData;
    } catch {
      return undefined;
    }
  }

  async save(sessionId: string, sessionData: SessionData<S>): Promise<void> {
    await fs.mkdir("sessions", { recursive: true });
    const s = JSON.stringify(sessionData);
    await fs.writeFile(`sessions/${sessionId}.json`, s, "utf8");
  }
}

export async function createChatSession(
  ai: GenkitBeta,
  modelType: ModelType,
  systemInstructions: string,
  maxTokens?: number,
  temperature?: number,
  stopSequences?: string[],
): Promise<string> {
  const store = new JsonSessionStore();
  const session = ai.createSession({ store });

  session.chat({
    model: modelMap[modelType],
    system: systemInstructions,
    config: {
      maxOutputTokens: maxTokens ?? 2048,
      temperature: temperature ?? 0.7,
      stopSequences: stopSequences ?? [],
    },
  });

  return session.id;
}

export async function sendMessagesToSession(
  ai: GenkitBeta,
  modelType: ModelType,
  sessionId: string,
  messages: string[],
  systemInstructions: string,
  maxTokens?: number,
  temperature?: number,
  stopSequences?: string[],
): Promise<string> {
  const store = new JsonSessionStore();
  const session = await ai.loadSession(sessionId, { store });
  const chatInstance = session.chat({
    model: modelMap[modelType],
    system: systemInstructions,
    config: {
      maxOutputTokens: maxTokens ?? 2048,
      temperature: temperature ?? 0.7,
      stopSequences: stopSequences ?? [],
    },
  });

  let responseText = "";
  for (const msg of messages) {
    try {
      const response = await chatInstance.send(msg);
      const text = response.text;
      if (text) {
        responseText += text + "\n";
      }
    } catch (error) {
      throw error;
    }
  }

  return responseText.trim();
}

export async function deleteSession(sessionId: string): Promise<void> {
  try {
    await unlink(`sessions/${sessionId}.json`);
  } catch (err) {
    throw err;
  }
}

export async function generateImage(
  ai: GenkitBeta,
  modelType: ImageModelType,
  prompt: string,
): Promise<string> {
  let config: any = {};

  switch (modelType) {
    case "dallE":
      config = {
        size: "1024x1024",
        style: "vivid",
      };
      break;
    default:
      break;
  }

  const imageResponse = await ai.generate({
    model: imageModelMap[modelType],
    prompt: prompt,
    config,
  });
  return imageResponse.media?.url ?? "";
}

export const initChatFlow = ai.defineFlow(
  {
    name: "initChatSession",
    inputSchema: z.object({
      modelType: z.enum(["gemini", "gpt", "grok"]),
      systemInstructions: z.string().default("You are friendly and helpful."),
      maxTokens: z.number().optional(),
      temperature: z.number().optional(),
      stopSequences: z.array(z.string()).optional(),
    }),
    outputSchema: z.object({
      sessionId: z.string(),
    }),
  },
  async ({ modelType, systemInstructions, maxTokens, temperature, stopSequences }) => {
    const sessionId = await createChatSession(ai, modelType, systemInstructions, maxTokens, temperature, stopSequences);
    return { sessionId };
  }
);

export const sendMessagesFlow = ai.defineFlow(
  {
    name: "sendMessagesToChat",
    inputSchema: z.object({
      sessionId: z.string(),
      modelType: z.enum(["gemini", "gpt", "grok"]),
      messages: z.array(z.string()),
      systemInstructions: z.string().default("You are friendly and helpful."),
      maxTokens: z.number().optional(),
      temperature: z.number().optional(),
      stopSequences: z.array(z.string()).optional(),
    }),
    outputSchema: z.object({
      response: z.string(),
    }),
  },
  async ({ sessionId, modelType, messages, systemInstructions, maxTokens, temperature, stopSequences }) => {
    const response = await sendMessagesToSession(
      ai, modelType, sessionId, messages,
      systemInstructions, maxTokens, temperature, stopSequences);
    return { response };
  }
);

export const deleteSessionFlow = ai.defineFlow(
  {
    name: "deleteChatSession",
    inputSchema: z.object({
      sessionId: z.string(),
    }),
    outputSchema: z.void(),
  },
  async ({ sessionId }) => {
    await deleteSession(sessionId);
    return;
  }
);

export const generateImageFlow = ai.defineFlow(
  {
    name: "generateImage",
    inputSchema: z.object({
      modelType: z.enum(["dallE"]),
      prompt: z.string(),
    }),
    outputSchema: z.object({
      imageUrl: z.string(),
    }),
  },
  async ({ modelType, prompt }) => {
    const imageUrl = await generateImage(ai, modelType, prompt);
    return { imageUrl };
  }
);

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const openAiApiKey = defineSecret('OPENAI_API_KEY');
const xAiApiKey = defineSecret('XAI_API_KEY');

export const initChat = onCallGenkit({
  secrets: [geminiApiKey, openAiApiKey, xAiApiKey],
}, initChatFlow);

export const sendMessages = onCallGenkit({
  secrets: [geminiApiKey, openAiApiKey, xAiApiKey],
}, sendMessagesFlow);

export const deleteChatSession = onCallGenkit({
  secrets: [geminiApiKey, openAiApiKey],
}, deleteSessionFlow);

export const generateImageFromPrompt = onCallGenkit({
  secrets: [geminiApiKey, openAiApiKey],
}, generateImageFlow);
