import {useCallback, useState} from "react";
import {UserResultMessages} from "@/constants";
import {ListStatus, type ListState} from "@/utils/list-state";
import {getUserList, type User} from "@/api/user";
import type {ServiceErrorHandler} from "@/hooks/use-service-error-handler";

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
