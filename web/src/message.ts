// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

export type Message = {
  readonly collection: string;
  readonly library: string;
  readonly loading: string;
  readonly loadError: string;
  readonly reload: string;
  readonly filter: {
    readonly all: string;
    readonly unread: string;
    readonly like: string;
  };
};

export const ja: Message = {
  collection: "コレクション",
  library: "ライブラリ",
  loading: "読込中…",
  loadError: "読み込みに失敗しました",
  reload: "ページリロード",
  filter: {
    all: "すべての本",
    unread: "未読",
    like: "好き",
  },
};

export const en: Message = {
  collection: "Collection",
  library: "Library",
  loading: "Loading…",
  loadError: "An error occurred while loading",
  reload: "Reload",
  filter: {
    all: "All",
    unread: "Unread",
    like: "Like",
  },
};

export const message: Message = navigator.language === "ja" ? ja : en;
