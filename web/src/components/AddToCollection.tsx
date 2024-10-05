import { useContext, useState } from "react";
import CircularProgress from "@mui/material/CircularProgress";
import Dialog from "@mui/material/Dialog";
import DialogTitle from "@mui/material/DialogTitle";
import List from "@mui/material/List";
import ListItem from "@mui/material/ListItem";
import ListItemButton from "@mui/material/ListItemButton";
import ListItemText from "@mui/material/ListItemText";
import { addBookToCollection, StateContext } from "../reducer";
import { message } from "../message";
import { Collection } from "../domain/collection";

type Props = {
  readonly bookId: string;
  readonly open: boolean;
  readonly onClose: () => void;
};

export const AddToCollection: React.FunctionComponent<Props> = (
  props: Props
) => {
  const { state, dispatch } = useContext(StateContext);
  const [calling, setCalling] = useState(false);

  const handleAddToCollection = async (collection: Collection) => {
    setCalling(true);
    try {
      await fetch(`/api/v1/collections/${collection.id}`, {
        method: "POST",
        body: JSON.stringify({ bookId: props.bookId }),
      });
      dispatch(addBookToCollection(props.bookId, collection.id));
      props.onClose();
    } catch (error) {
      console.error(error);
    } finally {
      setCalling(false);
    }
  };

  return (
    <Dialog open={props.open} onClose={props.onClose}>
      <DialogTitle>{message.commands.addToCollection}</DialogTitle>
      <List>
        {state.collections.map((collection) => (
          <ListItem key={collection.id}>
            <ListItemButton onClick={() => handleAddToCollection(collection)}>
              {calling && (
                <CircularProgress
                  size={24}
                  sx={{ marginLeft: "-8px", marginRight: "8px" }}
                />
              )}
              <ListItemText primary={collection.name} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Dialog>
  );
};
