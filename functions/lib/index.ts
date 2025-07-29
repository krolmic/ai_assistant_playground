import {googleAI} from '@genkit-ai/googleai';
import {setGlobalOptions} from "firebase-functions";
import {onCallGenkit} from 'firebase-functions/https';
import {defineSecret} from "firebase-functions/params";
import {promises as fs} from "fs";
import {unlink} from "fs/promises";
import {genkit,GenkitBeta,SessionData,SessionStore,z} from "genkit/beta";

setGlobalOptions({ maxInstances: 10 });

const ai = genkit({
  plugins: [
    googleAI(),
  ],
});

type ModelType = "gemini";
const modelMap: Record<ModelType, any> = {
  gemini: googleAI.model("gemini-2.5-flash", {
    temperature: 0.8,
  }),
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
    await fs.mkdir("sessions", {recursive: true});
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
  const session = ai.createSession({store});

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
  const session = await ai.loadSession(sessionId, {store});
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

export const initChatFlow = ai.defineFlow(
  {
    name: "initChatSession",
    inputSchema: z.object({
      modelType: z.enum(["gemini"]),
      systemInstructions: z.string().default("You are friendly and helpful."),
      maxTokens: z.number().optional(),
      temperature: z.number().optional(),
      stopSequences: z.array(z.string()).optional(),
    }),
    outputSchema: z.object({
      sessionId: z.string(),
    }),
  },
  async ({modelType, systemInstructions, maxTokens, temperature, stopSequences}) => {
    const sessionId = await createChatSession(ai, modelType, systemInstructions, maxTokens, temperature, stopSequences);
    return {sessionId};
  }
);

export const sendMessagesFlow = ai.defineFlow(
  {
    name: "sendMessagesToChat",
    inputSchema: z.object({
      sessionId: z.string(),
      modelType: z.enum(["gemini"]),
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
  async ({sessionId, modelType, messages, systemInstructions, maxTokens, temperature, stopSequences}) => {
    const response = await sendMessagesToSession(
      ai, modelType, sessionId, messages,
      systemInstructions, maxTokens, temperature, stopSequences);
    return {response};
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
  async ({sessionId}) => {
    await deleteSession(sessionId);
    return;
  }
);

const geminiApiKey = defineSecret('GEMINI_API_KEY');

export const initChat = onCallGenkit({
  secrets: [geminiApiKey],
}, initChatFlow);

export const sendMessages = onCallGenkit({
  secrets: [geminiApiKey],
}, sendMessagesFlow);

export const deleteChatSession = onCallGenkit({
  secrets: [geminiApiKey],
}, deleteSessionFlow);
