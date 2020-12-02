module ising
        implicit none
        public

        ! Basically smpin Array of up and down spins
        type :: smatrix
                integer :: row, col
                integer, allocatable, dimension(:, :) :: val
        end type

        contains

                ! invert a single spin
                integer function invertl(x)
                        implicit none
                        integer, intent(in) :: x
                        invertl = -1 * x
                end function

                ! for calculation of metropils probability
                real function listmap(a, f, list)
                        implicit none
                        integer , intent(in) :: a, f
                        real, dimension(:), intent(in) :: list
                        if ((a .eq. -1) .and. (f .eq. -4)) then
                                listmap = list(1)
                        else if ((a .eq. -1) .and. (f .eq. -2)) then
                                listmap = list(2)
                        else if ((a .eq. -1) .and. (f .eq. 0)) then
                                listmap = list(3)
                        else if ((a .eq. -1) .and. (f .eq. 2)) then
                                listmap = list(4)
                        else if ((a .eq. -1) .and. (f .eq. 4)) then
                                listmap = list(5)
                        else if ((a .eq. 1) .and. (f .eq. -4)) then
                                listmap = list(6)
                        else if ((a .eq. 1) .and. (f .eq. -2)) then
                                listmap = list(7)
                        else if ((a .eq. 1) .and. (f .eq. 0)) then
                                listmap = list(8)
                        else if ((a .eq. 1) .and. (f .eq. 2)) then
                                listmap = list(9)
                        else if ((a .eq. 1) .and. (f .eq. 4)) then
                                listmap = list(10)
                        endif
                end function

                ! Calculating f
                integer function fcal(sm, x, y)
                        implicit none
                        type(smatrix), intent(in) :: sm
                        integer, intent(in) :: x, y
                        integer, dimension(8) :: n
!                        x1, y1, x2, y2, x3, y3, x4, y4
                        integer :: i

                        n(1) = modulo(x + 1, sm%row)
                        n(2) = modulo(y, sm%row)
                        n(3) = modulo(x, sm%row)
                        n(4) = modulo(y + 1, sm%row)
                        n(5) = modulo(x - 1, sm%row)
                        n(6) = modulo(y, sm%row)
                        n(7) = modulo(x, sm%row)
                        n(8) = modulo(y - 1, sm%row)

                        do i = 1, 8
                                if (n(i) .eq. 0)        then
                                        n(i) = sm%row
                                endif
                        enddo

                        fcal = sm%val(n(1), n(2)) + sm%val(n(3), n(4)) &
                                + sm%val(n(5), n(6)) + sm%val(n(7), n(8))
                end function

                ! magnetization per spin
                real function magnetization(sm)
                        implicit none
                        type(smatrix), intent(in) :: sm
                        integer :: i, j
                        real :: zodh
                        zodh = 0
                        do i = 1, sm%row
                                do j = 1, sm%col
                                        zodh = zodh + sm%val(i, j)
                                enddo
                        enddo
                        magnetization = (1.0 / (sm%col * sm%row)) * zodh
                end function

                ! intialize random spin system
                subroutine intialize_random(sm, rows, cols)
                        implicit none
                        type(smatrix), intent(out) :: sm
                        integer , intent(in) :: rows, cols
                        integer :: i, j
                        real :: eta

                        allocate(sm%val(rows, cols))
                        sm%row = rows
                        sm%col = cols
                        call random_number(eta)
                        do i = 1, sm%row
                                do j = 1, sm%col
                                        if (eta .lt. 0.5) then
                                                sm%val(i, j) = 1
                                        else
                                                sm%val(i, j) = -1
                                        endif
                                enddo
                        enddo
                end subroutine intialize_random

                ! cleaning up spins
                subroutine cleanup(sm)
                        implicit none
                        type(smatrix), intent(inout) :: sm
                        deallocate(sm%val)
                        sm%row  = 0
                        sm%col  = 0
                end subroutine cleanup

                ! fliping a single spin state at xi, yi position from spin matrix
                subroutine ran_flip(sm, smt, xi, yi)
                        implicit none
                        integer, intent(out) :: xi, yi
                        type(smatrix), intent(in):: sm
                        type(smatrix), intent(inout):: smt
                        real :: x, y

                        smt%val = sm%val

                        call random_number(x)
                        call random_number(y)
                        xi = 1  +  floor(20 * x)
                        yi = 1  +  floor(20 * y)

                        smt%val(xi, yi) = invertl(sm%val(xi, yi))
                end subroutine ran_flip

                ! created list for calculating rejection
                subroutine rlist(r, j, b)
                        implicit none
                        real, intent(in) :: j, b
                        real, intent(out) :: r(:)
                        integer :: p, q
                        integer, dimension(5) :: f
                        integer, dimension(2) :: alpha
                        f = [-4, -2, 0, 2, 4]
                        alpha = [-1, 1]

                        do p = 1, 2
                                do q = 1, 5
                                        r((p -1) * 5 + q) = exp(-2 * alpha(p) * (j * f(q) + b))
                                enddo
                        enddo
                end subroutine

                ! Metropils Algorithim
                subroutine mertopolis(sm, list)
                        implicit none
                        type(smatrix), intent(inout) :: sm
                        real, dimension(:), intent(in) :: list
                        type(smatrix) :: smt
                        integer :: salpha, f
                        integer :: x, y
                        real :: neta

                        call intialize_random(smt, sm%row, sm%col)
                        call ran_flip(sm, smt, x, y)

                        salpha = smt%val(x, y)
                        f = fcal(smt, x, y)
                        call random_number(neta)
                        if ( listmap(salpha, f, list) > neta) then
                                sm = smt
                        endif

                        call cleanup(smt)

                end subroutine mertopolis

                ! A sweep. Runs Metropolis Algorithim N times
                subroutine sweep(sm, list)
                        implicit none
                        type(smatrix), intent(inout) :: sm
                        real, dimension(:), intent(in) :: list
                        integer :: i

                        do i = 1, sm%row * sm%col
                                call mertopolis(sm, list)
                        enddo
                end subroutine sweep

end module ising

