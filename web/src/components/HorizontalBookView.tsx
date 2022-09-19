// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { useEffect, useRef } from "react";
import Box from "@mui/material/Box";
import { Book } from "../domain/book";
import NavigationPage from "./NavigationPage";

type Props = Readonly<{
  book: Book;
  nextBook?: Book;
  direction: "left" | "right";
  onNext: () => void;
  onRandom: () => void;
}>;

const pages = (book: Book) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <Box
      key={i}
      display="flex"
      mx="auto"
      width="100%"
      height="100%"
      flexShrink={0}
      sx={{ scrollSnapAlign: "start" }}
    >
      <Box
        component="img"
        my="auto"
        mx="auto"
        maxHeight="100%"
        maxWidth="100%"
        src={`/images/books/${book.id}/pages/${i}`}
        display="block"
      />
    </Box>
  ));
};

const HorizontalBookView = (props: Props) => {
  const topRef = useRef<HTMLElement>(null);
  useEffect(() => {
    topRef.current?.scrollIntoView();
  }, [props.book]);

  return (
    <Box
      display="flex"
      flexDirection={props.direction === "right" ? "row" : "row-reverse"}
      sx={{
        width: "100%",
        height: "100vh",
        scrollSnapType: "x mandatory",
        overflowX: "auto",
      }}
    >
      <span ref={topRef} />
      {pages(props.book)}
      <Box
        display="flex"
        flexDirection="column"
        width="100%"
        height="100%"
        flexShrink={0}
        justifyContent="center"
        alignItems="center"
        sx={{ scrollSnapAlign: "start" }}
      >
        <NavigationPage
          book={props.book}
          nextBook={props.nextBook}
          onNext={props.onNext}
          onRandom={props.onRandom}
        />
      </Box>
    </Box>
  );
};

export default HorizontalBookView;
