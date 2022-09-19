// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { useEffect, useRef } from "react";
import ShuffleIcon from "@mui/icons-material/Shuffle";
import SkipNextIcon from "@mui/icons-material/SkipNext";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import { Book } from "../domain/book";
import { message } from "../message";

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
  const nextBook = props.nextBook;
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
        mx="auto"
        width="100%"
        height="100%"
        flexShrink={0}
        justifyContent="center"
        alignItems="center"
        sx={{ scrollSnapAlign: "start" }}
      >
        {nextBook ? (
          <Typography
            variant="h5"
            sx={{ marginY: (theme) => theme.spacing(2) }}
          >
            NEXT: 「{nextBook.name}」
          </Typography>
        ) : (
          false
        )}
        <Stack direction="row" spacing={2}>
          {nextBook ? (
            <Button
              variant="outlined"
              startIcon={<SkipNextIcon />}
              onClick={props.onNext}
            >
              {message.commands.next}
            </Button>
          ) : (
            false
          )}
          <Button
            color="secondary"
            variant="outlined"
            startIcon={<ShuffleIcon />}
            onClick={props.onRandom}
          >
            {message.random}
          </Button>
        </Stack>
      </Box>
    </Box>
  );
};

export default HorizontalBookView;
