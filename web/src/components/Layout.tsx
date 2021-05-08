// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

/** @jsxImportSource @emotion/react */
import AppBar from "@material-ui/core/AppBar";
import Button from "@material-ui/core/Button";
import Divider from "@material-ui/core/Divider";
import IconButton from "@material-ui/core/IconButton";
import List from "@material-ui/core/List";
import ListItem from "@material-ui/core/ListItem";
import ListItemText from "@material-ui/core/ListItemText";
import ListSubheader from "@material-ui/core/ListSubheader";
import Snackbar from "@material-ui/core/Snackbar";
import { useTheme } from "@material-ui/core/styles";
import SwipeableDrawer from "@material-ui/core/SwipeableDrawer";
import Toolbar from "@material-ui/core/Toolbar";
import Typography from "@material-ui/core/Typography";
import ChevronLeftIcon from "@material-ui/icons/ChevronLeft";
import MenuIcon from "@material-ui/icons/Menu";
import { Fragment, useContext, useEffect, useState } from "react";
import { useLocation, useNavigate } from "rocon/react";
import { message } from "../message";
import { LoadingState, StateContext } from "../reducer";
import { collectionRoutes, filterRoutes } from "./Routes";

const drawerWidth = 200;

type Props = {
  readonly title?: string;
  readonly children: React.ReactNode;
};

const Layout: React.FunctionComponent<Props> = (props: Props) => {
  const { state } = useContext(StateContext);
  const [open, setOpen] = useState(false);
  const theme = useTheme();
  const location = useLocation();
  const navigate = useNavigate();
  useEffect(() => {
    // close drawer when route changed
    setOpen(false);
  }, [location]);

  const handleDrawerOpen = () => {
    setOpen(true);
  };

  const handleDrawerClose = () => {
    setOpen(false);
  };

  const handleReload = () => {
    document.location.reload();
  };

  return (
    <Fragment>
      <div css={{ flexGrow: 1 }}>
        <AppBar position="static" id="appbar">
          <Toolbar css={{ justifyContent: "space-between" }}>
            <div css={{ flex: 1 }}>
              <IconButton
                edge="start"
                css={{ marginRight: theme.spacing(2) }}
                color="inherit"
                aria-label="menu"
                onClick={handleDrawerOpen}
              >
                <MenuIcon />
              </IconButton>
            </div>
            <Typography variant="h6">{props.title ?? "Fomalhaut2"}</Typography>
            <div
              css={{ flex: 1, display: "flex", justifyContent: "flex-end" }}
            />
          </Toolbar>
        </AppBar>
        <SwipeableDrawer
          anchor="left"
          open={open}
          css={{
            width: drawerWidth,
            flexShrink: 0,
            ".MuiDrawer-paper": { width: drawerWidth },
          }}
          classes={
            {
              //paper: classes.drawerPaper,
            }
          }
          onOpen={() => setOpen(true)}
          onClose={() => setOpen(false)}
        >
          <div
            css={{
              display: "flex",
              alignItems: "center",
              padding: theme.spacing(0, 1),
              justifyContent: "flex-end",
            }}
          >
            <IconButton onClick={handleDrawerClose}>
              <ChevronLeftIcon />
            </IconButton>
          </div>
          <Divider />
          <List
            subheader={<ListSubheader>{message.library}</ListSubheader>}
            dense
          >
            {state.filters.map((filter) => (
              <ListItem
                button
                key={filter.id}
                onClick={() => navigate(filterRoutes.route, { id: filter.id })}
              >
                <ListItemText primary={filter.name} />
              </ListItem>
            ))}
          </List>
          <List
            subheader={<ListSubheader>{message.collection}</ListSubheader>}
            dense
          >
            {state.collections.map((collection) => (
              <ListItem
                button
                key={collection.id}
                onClick={() =>
                  navigate(collectionRoutes.route, { id: collection.id })
                }
              >
                <ListItemText primary={collection.name} />
              </ListItem>
            ))}
          </List>
        </SwipeableDrawer>
        <Snackbar
          open={state.loading === LoadingState.Error}
          message={message.loadError}
          action={
            <Button color="primary" size="small" onClick={handleReload}>
              {message.reload}
            </Button>
          }
        />
      </div>
      <main>{props.children}</main>
    </Fragment>
  );
};
export default Layout;
