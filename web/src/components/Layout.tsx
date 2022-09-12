// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import MenuIcon from "@mui/icons-material/Menu";
import ShuffleIcon from "@mui/icons-material/Shuffle";
import SwipeLeftIcon from "@mui/icons-material/SwipeLeft";
import SwipeRightIcon from "@mui/icons-material/SwipeRight";
import SwipeDownIcon from "@mui/icons-material/SwipeDown";
import AppBar from "@mui/material/AppBar";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import Divider from "@mui/material/Divider";
import IconButton from "@mui/material/IconButton";
import List from "@mui/material/List";
import ListItemButton from "@mui/material/ListItemButton";
import ListItemText from "@mui/material/ListItemText";
import ListSubheader from "@mui/material/ListSubheader";
import Snackbar from "@mui/material/Snackbar";
import { useTheme } from "@mui/material/styles";
import SwipeableDrawer from "@mui/material/SwipeableDrawer";
import ToggleButton from "@mui/material/ToggleButton";
import ToggleButtonGroup from "@mui/material/ToggleButtonGroup";
import Toolbar from "@mui/material/Toolbar";
import Tooltip from "@mui/material/Tooltip";
import Typography from "@mui/material/Typography";
import { Fragment, useContext, useEffect, useState } from "react";
import { useLocation, useNavigate } from "rocon/react";
import { message } from "../message";
import { LoadingState, setViewMode, State, StateContext } from "../reducer";
import { bookRoutes, collectionRoutes, filterRoutes } from "./Routes";
// import ListItemLink from "./ListItemLink";

const drawerWidth = 200;

type Props = {
  readonly id?: string; // current id of collection or id of filter
  readonly title?: string;
  readonly children: React.ReactNode;
};

const Layout: React.FunctionComponent<Props> = (props: Props) => {
  const { dispatch, state } = useContext(StateContext);
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

  const handleRandom = () => {
    if (state.books.length > 0) {
      const index = Math.floor(Math.random() * state.books.length);
      const book = state.books[index];
      navigate(bookRoutes.anyRoute, { id: book.id });
    }
  };

  return (
    <Fragment>
      <Box flexGrow={1}>
        <AppBar position="static" id="appbar">
          <Toolbar sx={{ justifyContent: "space-between" }}>
            <Box flex={1}>
              <IconButton
                edge="start"
                sx={{ marginRight: theme.spacing(2) }}
                color="inherit"
                aria-label="menu"
                onClick={handleDrawerOpen}
              >
                <MenuIcon />
              </IconButton>
            </Box>
            <Typography variant="h6">{props.title ?? "Fomalhaut2"}</Typography>
            <Box display="flex" flex={1} justifyContent="flex-end">
              <ToggleButtonGroup
                value={state.viewMode}
                exclusive
                onChange={(_, value: State["viewMode"]) =>
                  dispatch(setViewMode(value))
                }
                sx={{ mr: 1 }}
              >
                <ToggleButton value="vertical">
                  <SwipeDownIcon />
                </ToggleButton>
                <ToggleButton value="left">
                  <SwipeLeftIcon />
                </ToggleButton>
                <ToggleButton value="right">
                  <SwipeRightIcon />
                </ToggleButton>
              </ToggleButtonGroup>
              <Tooltip title={message.random}>
                <IconButton size="large" color="inherit" onClick={handleRandom}>
                  <ShuffleIcon />
                </IconButton>
              </Tooltip>
            </Box>
          </Toolbar>
        </AppBar>
        <SwipeableDrawer
          anchor="left"
          open={open}
          sx={{
            width: drawerWidth,
            flexShrink: 0,
            ".MuiDrawer-paper": { width: drawerWidth },
          }}
          onOpen={() => setOpen(true)}
          onClose={() => setOpen(false)}
        >
          <Box
            display="flex"
            alignItems="center"
            justifyContent="flex-end"
            px={1}
          >
            <IconButton onClick={handleDrawerClose}>
              <ChevronLeftIcon />
            </IconButton>
          </Box>
          <Divider />
          <List
            subheader={
              <ListSubheader disableSticky>{message.library}</ListSubheader>
            }
            dense
          >
            {state.filters.map((filter) => (
              // ListItemLink causes re-render...
              // <ListItemLink
              //   key={filter.id}
              //   primary={filter.name}
              //   route={filterRoutes.route}
              //   match={{ id: filter.id }}
              // />
              <ListItemButton
                key={filter.id}
                selected={filter.id === props.id}
                onClick={() => navigate(filterRoutes.route, { id: filter.id })}
              >
                <ListItemText primary={filter.name} />
              </ListItemButton>
            ))}
          </List>
          <Divider />
          <List
            subheader={
              <ListSubheader disableSticky>{message.collection}</ListSubheader>
            }
            dense
          >
            {state.collections.map((collection) => (
              // <ListItemLink
              //   key={collection.id}
              //   primary={collection.name}
              //   route={collectionRoutes.route}
              //   match={{ id: collection.id }}
              // />
              <ListItemButton
                key={collection.id}
                selected={collection.id === props.id}
                onClick={() =>
                  navigate(collectionRoutes.route, { id: collection.id })
                }
              >
                <ListItemText primary={collection.name} />
              </ListItemButton>
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
      </Box>
      <main>{props.children}</main>
    </Fragment>
  );
};
export default Layout;
