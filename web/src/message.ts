// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

export type Message = {
  readonly collection: string;
  readonly library: string;
  readonly loading: string;
  readonly loadError: string;
  readonly reload: string;
  readonly random: string;
  readonly filter: {
    readonly all: string;
    readonly unread: string;
    readonly like: string;
  };
  readonly commands: {
    readonly scrollToTop: string;
    readonly like: string;
    readonly dislike: string;
    readonly next: string;
  };
};

export const ja: Message = {
  collection: "コレクション",
  library: "ライブラリ",
  loading: "読込中…",
  loadError: "読み込みに失敗しました",
  reload: "ページリロード",
  random: "ランダム",
  filter: {
    all: "すべての本",
    unread: "未読",
    like: "好き",
  },
  commands: {
    scrollToTop: "一番上に戻る",
    like: "好き",
    dislike: "好きを取り消し",
    next: "次の本を開く",
  },
};

export const en: Message = {
  collection: "Collection",
  library: "Library",
  loading: "Loading…",
  loadError: "An error occurred while loading",
  reload: "Reload",
  random: "Random",
  filter: {
    all: "All",
    unread: "Unread",
    like: "Like",
  },
  commands: {
    scrollToTop: "Go to page top",
    like: "Like",
    dislike: "Cancel Like",
    next: "Go to next book",
  },
};

export const message: Message = navigator.language === "ja" ? ja : en;
