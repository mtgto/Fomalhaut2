// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import ShuffleIcon from "@mui/icons-material/Shuffle";
import SkipNextIcon from "@mui/icons-material/SkipNext";
import Button from "@mui/material/Button";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import { Book } from "../domain/book.ts";
import { message } from "../message.ts";

type Props = Readonly<{
  book: Book;
  nextBook?: Book;
  onNext: () => void;
  onRandom: () => void;
}>;

const NavigationPage = (props: Props) => {
  return (
    <>
      {props.nextBook ? (
        <Typography variant="h5" sx={{ marginY: (theme) => theme.spacing(2) }}>
          NEXT: 「{props.nextBook.name}」
        </Typography>
      ) : (
        false
      )}
      <Stack direction="row" spacing={2}>
        {props.nextBook ? (
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
    </>
  );
};

export default NavigationPage;
