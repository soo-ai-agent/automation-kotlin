import {useCallback, useState} from "react";
import {type ListState} from "../../lib/listState";
import {ListStatus} from "../../enums/listStatus";
import {getUserList} from "../services/userService";
import {UserResultMessages} from "../enums/user";
import type {User} from "../types/user";
import type {ServiceErrorHandler} from "../../hooks/useServiceErrorHandler";

export function useUserList(handleError: ServiceErrorHandler) {
    const [users, setUsers] = useState<User[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [listState, setListState] = useState<ListState>({status: ListStatus.OK, message: ""});

    const loadUserList = useCallback(async (): Promise<void> => {
        setIsLoading(true);
        try {
            const loadedUsers: User[] = await getUserList();
            setUsers(loadedUsers);
            if (loadedUsers.length === 0) {
                setListState({status: ListStatus.EMPTY, message: UserResultMessages.LIST_EMPTY});
            } else {
                setListState({status: ListStatus.OK, message: ""});
            }
        } catch (error) {
            setUsers([]);
            setListState({status: ListStatus.ERROR, message: UserResultMessages.LIST_LOAD_ERROR});
            handleError(error, UserResultMessages.LIST_LOAD_ERROR);
        } finally {
            setIsLoading(false);
        }
    }, [handleError]);

    return {users, isLoading, listState, loadUserList};
}
