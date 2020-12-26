export type Message = {
  readonly collection: string;
  readonly library: string;
};

export const ja: Message = {
  collection: "コレクション",
  library: "ライブラリ",
};

export const en: Message = {
  collection: "Collection",
  library: "Library",
};

export const message: Message = navigator.language === "ja" ? ja : en;
