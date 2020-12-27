// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

export type Message = {
  readonly collection: string;
  readonly library: string;
  readonly loading: string;
  readonly loadError: string;
  readonly reload: string;
};

export const ja: Message = {
  collection: "コレクション",
  library: "ライブラリ",
  loading: "読込中…",
  loadError: "読み込みに失敗しました",
  reload: "ページリロード",
};

export const en: Message = {
  collection: "Collection",
  library: "Library",
  loading: "Loading…",
  loadError: "An error occurred while loading",
  reload: "Reload",
};

export const message: Message = navigator.language === "ja" ? ja : en;
