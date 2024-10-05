// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

export type Message = Readonly<{
  collection: string;
  library: string;
  loading: string;
  loadError: string;
  reload: string;
  random: string;
  settings: string;
  filter: Readonly<{
    all: string;
    unread: string;
    like: string;
  }>;
  commands: Readonly<{
    scrollToTop: string;
    like: string;
    dislike: string;
    addToCollection: string;
    next: string;
    prev: string;
  }>;
  viewMode: Readonly<{
    name: string;
    left: string;
    right: string;
    vertical: string;
  }>;
  sortOrder: Readonly<{
    header: string;
    name: string;
    readCount: string;
  }>;
}>;

export const ja: Message = {
  collection: "コレクション",
  library: "ライブラリ",
  loading: "読込中…",
  loadError: "読み込みに失敗しました",
  reload: "ページリロード",
  random: "ランダム",
  settings: "設定",
  filter: {
    all: "すべての本",
    unread: "未読",
    like: "好き",
  },
  commands: {
    scrollToTop: "一番上に戻る",
    like: "好き",
    dislike: "好きを取り消し",
    addToCollection: "コレクションに追加",
    next: "次の本を開く",
    prev: "前の本を開く",
  },
  viewMode: {
    name: "スクロール",
    left: "左方向",
    right: "右方向",
    vertical: "下方向",
  },
  sortOrder: {
    header: "順序",
    name: "名前順",
    readCount: "読んだ回数",
  },
};

export const en: Message = {
  collection: "Collection",
  library: "Library",
  loading: "Loading…",
  loadError: "An error occurred while loading",
  reload: "Reload",
  random: "Random",
  settings: "Settings",
  filter: {
    all: "All",
    unread: "Unread",
    like: "Like",
  },
  commands: {
    scrollToTop: "Go to page top",
    like: "Like",
    dislike: "Cancel Like",
    addToCollection: "Add to Collection",
    next: "Go to next book",
    prev: "Go to previous book",
  },
  viewMode: {
    name: "Scroll",
    left: "Left",
    right: "Right",
    vertical: "Down",
  },
  sortOrder: {
    header: "Sort by",
    name: "Name",
    readCount: "View Count",
  },
};

export const message: Message = navigator.language === "ja" ? ja : en;
