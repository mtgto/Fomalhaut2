import ShuffleIcon from "@mui/icons-material/Shuffle";
import SkipNextIcon from "@mui/icons-material/SkipNext";
import Button from "@mui/material/Button";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import { Book } from "../domain/book";
import { message } from "../message";

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
