import {useCallback, useEffect} from "react";
import {useUserDelete} from "./useUserDelete";
import {useUserList} from "./useUserList";
import {useUserModalRefs} from "./useUserModalRefs";
import {useUserSelection} from "./useUserSelection";
import {useServiceErrorHandler} from "../../hooks/useServiceErrorHandler";

export function useUsers() {
    const {handleError} = useServiceErrorHandler();
    const {users, isLoading, listState, loadUserList} = useUserList(handleError);
    const {selectedIds, isAllSelected, clearSelectedIds, toggleSelect, toggleSelectAll} = useUserSelection(users);
    const {detailModalRef, openDetail} = useUserModalRefs();

    const reloadUsers = useCallback(async (): Promise<void> => {
        await loadUserList();
        clearSelectedIds();
    }, [loadUserList, clearSelectedIds]);

    const {isDeleting, deleteOne, deleteSelected} = useUserDelete({selectedIds, reloadUsers, handleError});

    useEffect(() => {
        void reloadUsers();
    }, [reloadUsers]);

    return {
        table: {
            users, isLoading, listState, selectedIds, isAllSelected, isDeleting,
            toggleSelect, toggleSelectAll, openDetail, reloadUsers, deleteOne, deleteSelected,
        },
        modalRefs: {detailModalRef},
    };
}
